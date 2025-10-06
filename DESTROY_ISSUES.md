# Terraform Destroy Issues & Solutions

## Problem Summary

When running `terraform destroy`, two issues occurred:

1. **Helm release error**: `uninstall: Failed to purge the release: release: not found`
2. **Stuck subnet deletion**: Private subnet hangs for 13+ minutes during deletion

## Root Causes

### Issue 1: Helm Release Already Deleted
- The `kps` (kube-prometheus-stack) helm release was already destroyed (manually or by previous failed run)
- Terraform tries to destroy it again → "release: not found" error
- This happens when:
  - EKS cluster is destroyed before helm releases
  - kubectl context changes or becomes invalid
  - Manual cleanup was done

### Issue 2: ENIs Blocking Subnet Deletion
AWS subnets cannot be deleted while Network Interfaces (ENIs) are still attached.

Common sources of stuck ENIs:
1. **LoadBalancer Services** - Create AWS ELB/NLB with ENIs
2. **EKS Node ENIs** - Each node has ENIs for pod networking (AWS VPC CNI)
3. **EKS Security Groups** - Can have dependent ENIs
4. **Lambda Functions** - If deployed in VPC

The destroy order matters:
```
K8s Resources (LoadBalancers)
  → Helm Releases
    → EKS Cluster
      → Subnets
        → VPC
```

If EKS cluster is destroyed before K8s LoadBalancer services are cleaned up,
the ENIs remain orphaned and block subnet deletion.

## Solutions Implemented

### 1. Added Pre-Destroy Hook for LoadBalancer Cleanup
**File**: `main.tf:40-75`

**What it does**:
- Runs `kubectl delete svc` to remove all LoadBalancer services BEFORE cluster is destroyed
- Waits 30 seconds for cloud provider to clean up ENIs
- Only runs for managed clusters (AWS/Azure/GCP), not BYO mode
- Automatically triggered during `terraform destroy`

**Why it works**:
- Deletes LoadBalancers while kubectl still has access to the cluster
- Gives AWS time to detach and clean up ENIs
- Prevents orphaned ENIs from blocking subnet deletion

### 2. Fixed Conditional Resource Dependency
**File**: `main.tf:77-79` (was 50-52)

**Problem**:
```hcl
depends_on = [
  module.k8s_cluster,
  local_file.kubeconfig  # ❌ Has count=1, doesn't exist in BYO mode
]
```

**Fix**:
```hcl
depends_on = [
  module.k8s_cluster  # ✅ Always exists
]
```

### 3. Added Lifecycle Policy to Helm Releases
**File**: `deps/metrics_logs/main.tf`

**Added**:
```hcl
lifecycle {
  create_before_destroy = false
}
```

This ensures Terraform destroys helm releases in the correct order.

### 4. Created ENI Cleanup Script (For Manual Use)
**File**: `scripts/cleanup-stuck-enis.sh`

**Usage**:
```bash
# Find your VPC ID from terraform state
VPC_ID="vpc-0045f908478c03bbd"

# Run cleanup script
./scripts/cleanup-stuck-enis.sh $VPC_ID

# Retry destroy
terraform destroy -var-file examples/aws-config.tfvars -auto-approve
```

**What it does**:
1. Lists all ENIs in the VPC
2. Detaches ENIs managed by ELB/EKS
3. Deletes detached ENIs
4. Reports any failures for manual cleanup

## Recommended Destroy Procedure

### Option A: Normal Destroy (With Pre-Destroy Hook) ✅ AUTOMATIC
```bash
# Just run terraform destroy - the pre-destroy hook handles LoadBalancer cleanup
terraform destroy -var-file examples/aws-config.tfvars -auto-approve
```

**What happens**:
1. Pre-destroy hook deletes all LoadBalancer services
2. Waits 30s for AWS to clean up ENIs
3. Destroys helm releases
4. Destroys EKS cluster
5. Destroys VPC resources

### Option B: Manual Cleanup (If pre-destroy hook fails)
```bash
# 1. Get VPC ID from state
VPC_ID=$(terraform output -json vpc | jq -r '.vpc_id')

# 2. Clean up stuck ENIs
./scripts/cleanup-stuck-enis.sh $VPC_ID

# 3. Retry destroy
terraform destroy -var-file examples/aws-config.tfvars -auto-approve
```

### Option C: Nuclear Option (Last resort)
```bash
# 1. Remove problematic resources from state
terraform state rm 'module.vpc.aws_subnet.private[1]'
terraform state rm 'module.metrics_logs.helm_release.kps'
terraform state rm 'module.metrics_logs.helm_release.loki'

# 2. Clean up manually in AWS Console
# - Delete stuck ENIs
# - Delete stuck subnets
# - Delete VPC

# 3. Destroy remaining state
terraform destroy -var-file examples/aws-config.tfvars -auto-approve
```

## Prevention Strategies

### 1. Use Proper Destroy Dependencies
Ensure modules that create LoadBalancers depend on cluster:
```hcl
module "ingress_tls" {
  # ...
  depends_on = [module.k8s_cluster]
}
```

### 2. Add Pre-Destroy Hooks
Consider adding a pre-destroy script to remove LoadBalancers:
```hcl
resource "null_resource" "cleanup_loadbalancers" {
  triggers = {
    cluster_name = var.k8s_cluster.aws.cluster_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete svc --all -A --selector='type=LoadBalancer' || true"
  }
}
```

### 3. Use Terraform Timeouts
Add timeouts to subnet resources:
```hcl
resource "aws_subnet" "private" {
  # ...

  timeouts {
    delete = "10m"
  }
}
```

### 4. Monitor Destroy Progress
If destroy hangs:
```bash
# In another terminal, check for stuck ENIs
aws ec2 describe-network-interfaces \
  --region eu-central-1 \
  --filters "Name=vpc-id,Values=vpc-XXXXX" \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description,Status]' \
  --output table
```

## Known Limitations

1. **Helm Provider Limitation**: The helm provider can't destroy releases if the K8s cluster is already gone. This is expected behavior - just ignore the error and continue.

2. **AWS API Delays**: AWS can take 5-10 minutes to clean up ENIs after ELB deletion. Be patient or use the cleanup script.

3. **Orphaned Resources**: If destroy fails partway, you may need to manually clean up resources in AWS Console.

## Related Code Review Issues

This is related to Code Review issue #6 (main.tf:48-52) about conditional resource dependencies.

Fixed in this commit.
