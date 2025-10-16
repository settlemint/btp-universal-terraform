# FAQ

## Overview

This document provides answers to frequently asked questions about the SettleMint BTP Universal Terraform project. It covers common questions about deployment, configuration, troubleshooting, and best practices.

## Table of Contents

- [General Questions](#general-questions)
- [Deployment Questions](#deployment-questions)
- [Configuration Questions](#configuration-questions)
- [Troubleshooting Questions](#troubleshooting-questions)
- [Platform-Specific Questions](#platform-specific-questions)
- [Security Questions](#security-questions)
- [Performance Questions](#performance-questions)
- [Maintenance Questions](#maintenance-questions)

## General Questions

### What is the SettleMint BTP Universal Terraform project?

The SettleMint BTP Universal Terraform project is a comprehensive Infrastructure as Code (IaC) solution for deploying the SettleMint BTP (Blockchain Technology Platform) across multiple cloud providers and Kubernetes environments. It provides a unified interface for deploying the platform with all its dependencies.

### What platforms are supported?

The project supports the following platforms:
- **AWS**: Amazon Web Services with EKS, RDS, ElastiCache, S3, Cognito, and Secrets Manager
- **Azure**: Microsoft Azure with AKS, Azure Database for PostgreSQL, Azure Cache for Redis, Azure Blob Storage, Azure AD B2C, and Azure Key Vault
- **GCP**: Google Cloud Platform with GKE, Cloud SQL, Memorystore, Cloud Storage, Identity Platform, and Secret Manager
- **Generic**: Any Kubernetes cluster with Helm-deployed dependencies

### What is the three-mode pattern?

The three-mode pattern is a design principle used throughout the project where each dependency can be deployed in three ways:
1. **Kubernetes (k8s)**: Deploy using Helm charts within the Kubernetes cluster
2. **Managed**: Use cloud provider managed services (AWS RDS, Azure Database, GCP Cloud SQL, etc.)
3. **BYO (Bring Your Own)**: Connect to existing external services

### What are the main components of the BTP platform?

The main components include:
- **BTP Platform**: The core SettleMint application
- **PostgreSQL**: Database for storing application data
- **Redis**: Caching and session storage
- **Object Storage**: File and artifact storage (MinIO, S3, Azure Blob, GCS)
- **OAuth/Identity**: Authentication and authorization (Keycloak, Cognito, Azure AD B2C, Identity Platform)
- **Secrets Management**: Secure storage of sensitive data (Vault, Secrets Manager, Key Vault, Secret Manager)
- **Observability**: Monitoring, logging, and alerting (Prometheus, Grafana, Loki, CloudWatch, Azure Monitor, Cloud Monitoring)

### What are the system requirements?

**Minimum Requirements:**
- Kubernetes cluster with at least 3 nodes
- 4 CPU cores and 8GB RAM per node
- 100GB storage per node
- Kubernetes version 1.24 or higher
- Helm 3.8 or higher

**Recommended Requirements:**
- Kubernetes cluster with at least 5 nodes
- 8 CPU cores and 16GB RAM per node
- 200GB storage per node
- Kubernetes version 1.28 or higher
- Helm 3.12 or higher

## Deployment Questions

### How do I get started with a basic deployment?

1. **Clone the repository:**
   ```bash
   git clone https://github.com/settlemint/btp-universal-terraform.git
   cd btp-universal-terraform
   ```

2. **Choose a configuration:**
   ```bash
   # For AWS
   cp examples/aws-config.tfvars my-config.tfvars
   
   # For Azure
   cp examples/azure-config.tfvars my-config.tfvars
   
   # For GCP
   cp examples/gcp-config.tfvars my-config.tfvars
   
   # For Kubernetes-only
   cp examples/k8s-config.tfvars my-config.tfvars
   ```

3. **Configure your variables:**
   Edit `my-config.tfvars` with your specific values.

4. **Deploy:**
   ```bash
   terraform init
   terraform plan -var-file=my-config.tfvars
   terraform apply -var-file=my-config.tfvars
   ```

### How long does a deployment take?

Deployment times vary based on the configuration:
- **Kubernetes-only**: 10-15 minutes
- **AWS with managed services**: 20-30 minutes
- **Azure with managed services**: 25-35 minutes
- **GCP with managed services**: 20-30 minutes
- **Full production setup**: 30-45 minutes

### Can I deploy to multiple environments?

Yes, you can deploy to multiple environments by:
1. Using different variable files for each environment
2. Using different Terraform workspaces
3. Using different state backends for each environment

Example:
```bash
# Development
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform apply -var-file=environments/staging.tfvars

# Production
terraform apply -var-file=environments/production.tfvars
```

### How do I update an existing deployment?

1. **Update your configuration:**
   Edit your `.tfvars` file with the new values.

2. **Plan the changes:**
   ```bash
   terraform plan -var-file=my-config.tfvars
   ```

3. **Apply the changes:**
   ```bash
   terraform apply -var-file=my-config.tfvars
   ```

### Can I deploy without creating a new Kubernetes cluster?

Yes, you can use an existing Kubernetes cluster by setting:
```hcl
cluster = {
  create = false
  name   = "your-existing-cluster"
  region = "your-region"
}
```

## Configuration Questions

### How do I configure custom domains?

Set the `base_domain` variable in your configuration:
```hcl
base_domain = "btp.example.com"
```

The system will automatically configure:
- Platform: `https://btp.example.com`
- API: `https://api.btp.example.com`
- Auth: `https://auth.btp.example.com`
- Grafana: `https://grafana.btp.example.com`
- Prometheus: `https://prometheus.btp.example.com`

### How do I configure SSL/TLS certificates?

The system automatically configures SSL/TLS certificates using Let's Encrypt via cert-manager. No additional configuration is required.

For custom certificates, you can:
1. Provide your own certificate through the ingress configuration
2. Use a custom cert-manager issuer
3. Configure manual certificate management

### How do I configure authentication providers?

Configure OAuth providers in your `.tfvars` file:

**For Keycloak (Kubernetes mode):**
```hcl
oauth = {
  mode = "k8s"
  k8s = {
    # Keycloak configuration
    admin_username = "admin"
    admin_password = "secure-password"
  }
}
```

**For AWS Cognito:**
```hcl
oauth = {
  mode = "aws"
  aws = {
    user_pool_name = "btp-users"
    # Cognito configuration
  }
}
```

### How do I configure database connections?

Database connections are automatically configured based on your deployment mode:

**Kubernetes mode:**
```hcl
postgres = {
  mode = "k8s"
  k8s = {
    password = "secure-password"
  }
}
```

**AWS RDS:**
```hcl
postgres = {
  mode = "aws"
  aws = {
    cluster_id = "btp-postgres"
    node_type  = "db.t3.medium"
  }
}
```

### How do I configure monitoring and alerting?

Monitoring is automatically configured based on your deployment mode:

**Kubernetes mode:**
```hcl
metrics_logs = {
  mode = "k8s"
  k8s = {
    prometheus = {
      chart_version = "51.4.0"
    }
    grafana = {
      chart_version = "7.0.12"
      admin_password = "secure-password"
    }
  }
}
```

**AWS CloudWatch:**
```hcl
metrics_logs = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    log_groups = [...]
    alarms = [...]
  }
}
```

## Troubleshooting Questions

### My pods are stuck in Pending state. What should I do?

1. **Check node capacity:**
   ```bash
   kubectl describe nodes
   kubectl top nodes
   ```

2. **Check resource quotas:**
   ```bash
   kubectl describe quota -n settlemint
   ```

3. **Check persistent volume claims:**
   ```bash
   kubectl get pvc -A
   ```

4. **Check storage classes:**
   ```bash
   kubectl get storageclass
   ```

**Common solutions:**
- Scale up your cluster nodes
- Increase resource quotas
- Fix storage class configuration
- Check node selector and tolerations

### My application is not accessible. How do I troubleshoot?

1. **Check ingress configuration:**
   ```bash
   kubectl get ingress -A
   kubectl describe ingress -n settlemint
   ```

2. **Check service endpoints:**
   ```bash
   kubectl get endpoints -A
   ```

3. **Check DNS resolution:**
   ```bash
   nslookup btp.example.com
   ```

4. **Check certificate status:**
   ```bash
   kubectl get certificates -A
   ```

**Common solutions:**
- Verify DNS configuration
- Check certificate status
- Verify ingress controller is running
- Check network policies

### How do I troubleshoot database connection issues?

1. **Check database pod status:**
   ```bash
   kubectl get pods -n btp-deps | grep postgres
   kubectl logs -n btp-deps deployment/postgres
   ```

2. **Test database connectivity:**
   ```bash
   kubectl run postgres-test --rm -i --tty --image postgres:15 -- psql -h postgres.btp-deps.svc.cluster.local -U btp_user -d btp
   ```

3. **Check database configuration:**
   ```bash
   kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SHOW ALL;"
   ```

**Common solutions:**
- Restart database pods
- Check network policies
- Verify credentials
- Check database logs

### How do I troubleshoot authentication issues?

1. **Check OAuth service status:**
   ```bash
   kubectl get pods -n btp-deps | grep keycloak
   kubectl logs -n btp-deps deployment/keycloak
   ```

2. **Test OAuth endpoints:**
   ```bash
   curl -f https://auth.btp.example.com/realms/btp/.well-known/openid_configuration
   ```

3. **Check JWT configuration:**
   ```bash
   kubectl get configmap btp-jwt-config -n settlemint -o yaml
   ```

**Common solutions:**
- Restart OAuth service
- Check JWT configuration
- Verify client credentials
- Check network connectivity

### How do I troubleshoot performance issues?

1. **Check resource usage:**
   ```bash
   kubectl top pods -A
   kubectl top nodes
   ```

2. **Check application metrics:**
   ```bash
   kubectl exec -n settlemint deployment/btp-platform -- curl localhost:8080/metrics
   ```

3. **Check database performance:**
   ```bash
   kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
   ```

**Common solutions:**
- Scale up resources
- Optimize database queries
- Enable caching
- Check network latency

## Platform-Specific Questions

### AWS-Specific Questions

#### How do I configure AWS EKS?

```hcl
cluster = {
  create = true
  name   = "btp-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.medium"]
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
  }
}
```

#### How do I configure AWS RDS?

```hcl
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-postgres"
    engine_version             = "15.4"
    node_type                  = "db.t3.medium"
    multi_az                   = true
    backup_retention_period    = 30
  }
}
```

#### How do I configure AWS ElastiCache?

```hcl
redis = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-redis"
    engine_version             = "7.0"
    node_type                  = "cache.t3.medium"
    multi_az                   = true
    automatic_failover_enabled = true
  }
}
```

#### How do I configure AWS S3?

```hcl
object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-artifacts"
    region             = "us-east-1"
    versioning_enabled = true
  }
}
```

### Azure-Specific Questions

#### How do I configure Azure AKS?

```hcl
cluster = {
  create = true
  name   = "btp-cluster"
  region = "East US"
  node_groups = {
    main = {
      instance_types = ["Standard_D2s_v3"]
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
  }
}
```

#### How do I configure Azure Database for PostgreSQL?

```hcl
postgres = {
  mode = "azure"
  azure = {
    cache_name          = "btp-postgres"
    location            = "East US"
    resource_group_name = "btp-resources"
    capacity            = 1
    family              = "Gen5"
    sku_name            = "GP_Gen5_2"
  }
}
```

#### How do I configure Azure Cache for Redis?

```hcl
redis = {
  mode = "azure"
  azure = {
    cache_name          = "btp-redis"
    location            = "East US"
    resource_group_name = "btp-resources"
    capacity            = 1
    family              = "C"
    sku_name            = "Standard"
  }
}
```

### GCP-Specific Questions

#### How do I configure GCP GKE?

```hcl
cluster = {
  create = true
  name   = "btp-cluster"
  region = "us-central1"
  node_groups = {
    main = {
      instance_types = ["e2-medium"]
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
  }
}
```

#### How do I configure GCP Cloud SQL?

```hcl
postgres = {
  mode = "gcp"
  gcp = {
    instance_name  = "btp-postgres"
    tier           = "db-f1-micro"
    memory_size_gb = 1
    region         = "us-central1"
  }
}
```

#### How do I configure GCP Memorystore?

```hcl
redis = {
  mode = "gcp"
  gcp = {
    instance_name  = "btp-redis"
    tier           = "BASIC"
    memory_size_gb = 1
    region         = "us-central1"
  }
}
```

## Security Questions

### How is security configured by default?

The system includes comprehensive security by default:
- **Network isolation**: Private subnets and security groups
- **TLS encryption**: All communications encrypted
- **RBAC**: Role-based access control
- **Secrets management**: Secure storage of sensitive data
- **Pod security**: Non-root containers and security contexts
- **Network policies**: Traffic isolation between namespaces

### How do I configure custom security policies?

**Network policies:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: custom-network-policy
  namespace: settlemint
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
```

**Pod security policies:**
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: custom-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
```

### How do I rotate secrets?

**Database passwords:**
```bash
kubectl create secret generic postgres-secret \
  --from-literal=password=new-secure-password \
  --dry-run=client -o yaml | kubectl apply -f -
```

**API keys:**
```bash
kubectl create secret generic btp-api-keys \
  --from-literal=api-key=new-api-key \
  --dry-run=client -o yaml | kubectl apply -f -
```

**JWT signing keys:**
```bash
kubectl create secret generic jwt-signing-key \
  --from-literal=signing-key=new-jwt-signing-key \
  --dry-run=client -o yaml | kubectl apply -f -
```

### How do I enable audit logging?

Audit logging is automatically configured for Kubernetes clusters. For application-level auditing:

```hcl
btp = {
  values = {
    env = [
      {
        name  = "AUDIT_ENABLED"
        value = "true"
      },
      {
        name  = "AUDIT_LEVEL"
        value = "info"
      }
    ]
  }
}
```

## Performance Questions

### How do I optimize performance?

**Resource optimization:**
```hcl
btp = {
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu    = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu    = "2000m"
      }
    }
  }
}
```

**Autoscaling:**
```hcl
btp = {
  values = {
    autoscaling = {
      enabled = true
      minReplicas = 3
      maxReplicas = 20
      targetCPUUtilizationPercentage = 60
      targetMemoryUtilizationPercentage = 70
    }
  }
}
```

**Database optimization:**
```hcl
postgres = {
  mode = "k8s"
  k8s = {
    values = {
      postgresqlConfiguration = |
        shared_buffers = 256MB
        effective_cache_size = 1GB
        maintenance_work_mem = 64MB
    }
  }
}
```

### How do I monitor performance?

**Prometheus metrics:**
```bash
kubectl exec -n settlemint deployment/btp-platform -- curl localhost:8080/metrics
```

**Grafana dashboards:**
Access Grafana at `https://grafana.btp.example.com` with the admin credentials.

**Application logs:**
```bash
kubectl logs -n settlemint deployment/btp-platform --tail=100 -f
```

### How do I scale the deployment?

**Horizontal scaling:**
```bash
kubectl scale deployment btp-platform --replicas=5 -n settlemint
```

**Vertical scaling:**
```bash
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"requests":{"cpu":"1000m","memory":"1Gi"},"limits":{"cpu":"2000m","memory":"2Gi"}}}]}}}}'
```

**Cluster scaling:**
```bash
# AWS EKS
aws eks update-nodegroup-config --cluster-name btp-cluster --nodegroup-name btp-nodes --scaling-config minSize=3,maxSize=10,desiredSize=5

# Azure AKS
az aks scale --resource-group btp-resources --name btp-cluster --node-count 5

# GCP GKE
gcloud container clusters resize btp-cluster --num-nodes=5 --zone=us-central1-a
```

## Maintenance Questions

### How do I backup my deployment?

**Automated backup script:**
```bash
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Database backup
kubectl exec -n btp-deps deployment/postgres -- pg_dump -U btp_user -d btp > "$BACKUP_DIR/btp-database.sql"

# MinIO backup
kubectl exec -n btp-deps deployment/minio -- mc mirror local/btp-artifacts "$BACKUP_DIR/minio-data"

# Vault backup
kubectl exec -n btp-deps deployment/vault -- vault operator raft snapshot save "$BACKUP_DIR/vault.snapshot"

# Kubernetes resources backup
kubectl get all -A -o yaml > "$BACKUP_DIR/kubernetes-resources.yaml"
```

### How do I update the platform?

**Update BTP platform:**
```bash
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:v2.1.0 -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint
```

**Update dependencies:**
```bash
# PostgreSQL
helm upgrade postgres bitnami/postgresql -n btp-deps --set image.tag=15.4

# Redis
helm upgrade redis bitnami/redis -n btp-deps --set image.tag=7.2

# MinIO
helm upgrade minio bitnami/minio -n btp-deps --set image.tag=RELEASE.2024-01-01T00-00-00Z
```

### How do I perform maintenance tasks?

**Weekly maintenance:**
```bash
#!/bin/bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean up old Docker images
docker system prune -f

# Clean up old Kubernetes resources
kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces
kubectl delete pods --field-selector=status.phase=Failed --all-namespaces

# Database maintenance
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "VACUUM ANALYZE;"
```

**Monthly maintenance:**
```bash
#!/bin/bash
# Update Helm charts
helm repo update
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack -n btp-deps
helm upgrade grafana grafana/grafana -n btp-deps

# Update container images
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:latest -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint

# Database backup
kubectl exec -n btp-deps deployment/postgres -- pg_dump -U btp_user -d btp > /tmp/btp-db-backup-$(date +%Y%m%d).sql
```

### How do I troubleshoot common issues?

**Pod issues:**
```bash
# Check pod status
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)"

# Check pod logs
kubectl logs -n settlemint deployment/btp-platform --previous

# Check pod events
kubectl describe pod -n settlemint -l app=btp-platform
```

**Service issues:**
```bash
# Check service endpoints
kubectl get endpoints -A

# Check service selector
kubectl get svc -A -o yaml

# Test service connectivity
kubectl run test-pod --rm -i --tty --image busybox -- nslookup btp-platform.settlemint.svc.cluster.local
```

**Network issues:**
```bash
# Check DNS resolution
kubectl run dns-test --rm -i --tty --image busybox -- nslookup kubernetes.default.svc.cluster.local

# Check network connectivity
kubectl run network-test --rm -i --tty --image busybox -- nc -zv postgres.btp-deps.svc.cluster.local 5432

# Check network policies
kubectl get networkpolicies -A
```

## Next Steps

- [Contributing](25-contributing.md) - Contributing guidelines
- [Changelog](26-changelog.md) - Version history
- [Support](27-support.md) - Getting help
- [Community](28-community.md) - Community resources

---

*This FAQ provides answers to the most common questions about the SettleMint BTP Universal Terraform project. If you don't find the answer to your question here, please check the other documentation or reach out to the community for support.*
