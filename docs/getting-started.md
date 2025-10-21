# Getting Started

## Prerequisites

Install these tools:
- Terraform 1.6 or newer
- `kubectl` and `helm` for your target cluster
- Optional: OrbStack, kind, or minikube for local testing

**For AWS managed services**, configure credentials with permissions for:
- VPC, EC2, IAM
- RDS, ElastiCache, S3
- Cognito, Route53

## Install the stack in four steps

**1. Initialize Terraform**
```bash
terraform init
```

**2. Review changes**
```bash
terraform plan -var-file examples/k8s-config.tfvars
```

**3. Apply configuration**
```bash
terraform apply -var-file examples/k8s-config.tfvars
```

**4. Clean up when done**
```bash
terraform destroy -var-file examples/k8s-config.tfvars
```

**Customize inputs** – See [Configuration](configuration.md) for variables you can override.

## Choose an example profile

**Local development**
```bash
examples/k8s-config.tfvars        # All dependencies in-cluster
```

**AWS managed services**
```bash
examples/aws-config.tfvars        # RDS, ElastiCache, S3, Cognito
examples/mixed-config.tfvars      # Mix AWS managed + in-cluster
```

**Other clouds** (bring-your-own endpoints)
```bash
examples/azure-config.tfvars
examples/gcp-config.tfvars
examples/byo-config.tfvars
```

## Verify the deployment

**Check ingress is accessible**
```bash
terraform output post_deploy_message
```

**View all service URLs**
```bash
terraform output -json post_deploy_urls
```

**Get kubeconfig** (when Terraform creates the cluster)
```bash
terraform output -json k8s_cluster | jq -r '.value.kubeconfig' > kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get pods -A
```

**For AWS managed mode**, check the AWS console for RDS, ElastiCache, and S3 resources.
