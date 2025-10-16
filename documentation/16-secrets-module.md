# Secrets Module

## Overview

The Secrets module provides a unified interface for deploying secrets management across multiple platforms and deployment modes. It supports the three-mode pattern: Kubernetes-native (Vault), managed cloud services, and Bring Your Own (BYO) external secrets management.

## Module Architecture

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TB
    subgraph "Secrets Module"
        MODE_SELECTION[Mode Selection]
        
        subgraph "Deployment Modes"
            K8S_MODE[<img src="assets/icons/k8s/kubernetes.svg" width="20"/> Kubernetes Mode]
            AWS_MODE[<img src="assets/icons/aws/secrets-manager.svg" width="20"/> AWS Secrets Mode]
            AZURE_MODE[<img src="assets/icons/azure/key-vault.svg" width="20"/> Azure Key Vault Mode]
            GCP_MODE[<img src="assets/icons/gcp/secret-manager.svg" width="20"/> GCP Secret Mode]
            BYO_MODE[<img src="assets/icons/security/external.svg" width="20"/> BYO Mode]
        end
        
        subgraph "Kubernetes Mode Components"
            VAULT_HELM[<img src="assets/icons/k8s/helm.svg" width="20"/> Vault Helm Chart]
            VAULT_CLUSTER[<img src="assets/icons/security/vault.svg" width="20"/> Vault Cluster]
            CONSUL_BACKEND[<img src="assets/icons/database/consul.svg" width="20"/> Consul Backend]
        end
        
        subgraph "Managed Mode Components"
            SECRETS_MANAGER[<img src="assets/icons/aws/secrets-manager.svg" width="20"/> Secrets Manager]
            KEY_VAULT[<img src="assets/icons/azure/key-vault.svg" width="20"/> Key Vault]
            SECRET_MANAGER[<img src="assets/icons/gcp/secret-manager.svg" width="20"/> Secret Manager]
        end
        
        subgraph "Output Normalization"
            NORMALIZED[<img src="assets/icons/tools/normalize.svg" width="20"/> Normalized Outputs]
            ENDPOINT[Endpoint]
            TOKEN[Token]
            NAMESPACE[Namespace]
            ENGINE[Engine]
            ADMIN_TOKEN[Admin Token]
        end
    end
    
    MODE_SELECTION --> K8S_MODE
    MODE_SELECTION --> AWS_MODE
    MODE_SELECTION --> AZURE_MODE
    MODE_SELECTION --> GCP_MODE
    MODE_SELECTION --> BYO_MODE
    
    K8S_MODE --> VAULT_HELM
    VAULT_HELM --> VAULT_CLUSTER
    VAULT_CLUSTER --> CONSUL_BACKEND
    
    AWS_MODE --> SECRETS_MANAGER
    AZURE_MODE --> KEY_VAULT
    GCP_MODE --> SECRET_MANAGER
    
    K8S_MODE --> NORMALIZED
    AWS_MODE --> NORMALIZED
    AZURE_MODE --> NORMALIZED
    GCP_MODE --> NORMALIZED
    BYO_MODE --> NORMALIZED
    
    NORMALIZED --> ENDPOINT
    NORMALIZED --> TOKEN
    NORMALIZED --> NAMESPACE
    NORMALIZED --> ENGINE
    NORMALIZED --> ADMIN_TOKEN
    
    classDef mode fill:#E3F2FD,stroke:#1976D2,color:#333
    classDef k8s fill:#326CE5,stroke:#fff,color:#fff
    classDef aws fill:#FF9900,stroke:#232F3E,color:#fff
    classDef azure fill:#0078D4,stroke:#005A9E,color:#fff
    classDef gcp fill:#EA4335,stroke:#4285F4,color:#fff
    classDef byo fill:#666,stroke:#333,color:#fff
    classDef output fill:#E8F5E8,stroke:#388E3C,color:#333
    
    class MODE_SELECTION mode
    class K8S_MODE,VAULT_HELM,VAULT_CLUSTER,CONSUL_BACKEND k8s
    class AWS_MODE,SECRETS_MANAGER aws
    class AZURE_MODE,KEY_VAULT azure
    class GCP_MODE,SECRET_MANAGER gcp
    class BYO_MODE byo
    class NORMALIZED,ENDPOINT,TOKEN,NAMESPACE,ENGINE,ADMIN_TOKEN output
```

## Configuration Options

### Mode Selection

The module supports five deployment modes:

| Mode | Description | Use Case |
|------|-------------|----------|
| **k8s** | Kubernetes-native deployment using Vault | Development, testing, or when you want full control |
| **aws** | AWS Secrets Manager managed service | Production environments requiring AWS integration |
| **azure** | Azure Key Vault managed service | Production environments on Azure |
| **gcp** | Google Secret Manager managed service | Production environments on GCP |
| **byo** | Bring Your Own external secrets management | Enterprise environments with existing secrets infrastructure |

### Common Configuration

```hcl
module "secrets" {
  source = "./deps/secrets"
  
  mode             = "k8s"                    # Deployment mode
  namespace        = "btp-deps"              # Kubernetes namespace
  manage_namespace = true                    # Whether to manage the namespace
  base_domain      = "btp.example.com"       # Base domain for ingress
  
  # Provider-specific configurations
  k8s   = {...}   # Kubernetes configuration
  aws   = {...}   # AWS configuration
  azure = {...}   # Azure configuration
  gcp   = {...}   # GCP configuration
  byo   = {...}   # BYO configuration
}
```

## Deployment Modes

### Kubernetes Mode (k8s)

Deploys Vault using the official Vault Helm chart for Kubernetes-native secrets management.

#### Features
- **High Availability**: Multi-replica Vault cluster with Consul backend
- **Secrets Engine**: Multiple secrets engines (KV, PKI, AWS, etc.)
- **Authentication**: Multiple authentication methods (Kubernetes, AWS, Azure, etc.)
- **Encryption**: Encryption at rest and in transit
- **Audit Logging**: Comprehensive audit logging
- **Policy Management**: Fine-grained access control policies

#### Configuration
```hcl
secrets = {
  mode = "k8s"
  k8s = {
    namespace      = "btp-deps"
    chart_version  = "0.26.0"
    release_name   = "vault"
    
    # High Availability
    ha = {
      enabled = true
      replicas = 3
      raft = {
        enabled = true
        setNodeId = true
      }
    }
    
    # Consul backend
    consul = {
      enabled = true
      address = "consul.btp-deps.svc.cluster.local:8500"
      path = "vault"
    }
    
    # Ingress configuration
    ingress = {
      enabled = true
      hosts = ["vault.btp.example.com"]
      tls = [{
        secretName = "vault-tls"
        hosts = ["vault.btp.example.com"]
      }]
    }
    
    # Service configuration
    service = {
      type = "ClusterIP"
      port = 8200
    }
    
    # Custom values
    values = {
      global = {
        tlsDisable = false
      }
      
      server = {
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
        
        # Vault configuration
        extraEnvironmentVars = {
          VAULT_CACERT = "/vault/tls/ca.crt"
          VAULT_CAPATH = "/vault/tls"
        }
      }
    }
  }
}
```

#### Vault with Raft Backend
```hcl
secrets = {
  mode = "k8s"
  k8s = {
    # Raft backend configuration
    ha = {
      enabled = true
      replicas = 3
      raft = {
        enabled = true
        setNodeId = true
        storage = {
          size = "10Gi"
          storageClass = "gp2"
        }
      }
    }
    
    # Disable Consul
    consul = {
      enabled = false
    }
  }
}
```

#### Vault with External Consul
```hcl
secrets = {
  mode = "k8s"
  k8s = {
    # External Consul configuration
    consul = {
      enabled = true
      address = "external-consul.company.com:8500"
      path = "vault"
      
      # Consul authentication
      auth = {
        enabled = true
        token = "consul-auth-token"
      }
    }
    
    # Disable built-in Consul
    consul-ha = {
      enabled = false
    }
  }
}
```

### AWS Mode (aws)

Deploys secrets management using AWS Secrets Manager managed service.

#### Features
- **Managed Service**: Fully managed secrets service
- **Automatic Rotation**: Automatic secret rotation
- **Cross-Region Replication**: Replicate secrets across regions
- **Integration**: Integration with AWS services
- **Encryption**: KMS encryption at rest
- **Access Control**: IAM-based access control

#### Configuration
```hcl
secrets = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    
    # Secrets configuration
    secrets = [{
      name = "btp-postgres-password"
      description = "PostgreSQL password for BTP platform"
      secret_string = jsonencode({
        username = "btp_user"
        password = "secure-postgres-password"
        engine = "postgres"
        host = "postgres.btp-deps.svc.cluster.local"
        port = 5432
        dbname = "btp"
      })
      
      # Automatic rotation
      rotation_config = {
        enabled = true
        rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-postgres-password"
        rotation_days = 30
      }
    }, {
      name = "btp-redis-password"
      description = "Redis password for BTP platform"
      secret_string = jsonencode({
        password = "secure-redis-password"
        host = "redis.btp-deps.svc.cluster.local"
        port = 6379
      })
    }]
    
    # KMS encryption
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    
    # Resource policy
    resource_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid = "AllowBTPAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/btp-role"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }]
    })
  }
}
```

#### AWS with Cross-Region Replication
```hcl
secrets = {
  mode = "aws"
  aws = {
    # Primary region
    region = "us-east-1"
    
    # Cross-region replication
    replication = [{
      region = "us-west-2"
      kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/87654321-4321-4321-4321-210987654321"
    }]
    
    secrets = [{
      name = "btp-critical-secret"
      description = "Critical secret with cross-region replication"
      secret_string = jsonencode({
        api_key = "critical-api-key"
        database_url = "postgresql://user:pass@host:5432/db"
      })
      
      # Replication configuration
      replication_config = {
        enabled = true
        regions = ["us-west-2"]
      }
    }]
  }
}
```

### Azure Mode (azure)

Deploys secrets management using Azure Key Vault managed service.

#### Features
- **Managed Service**: Fully managed key vault service
- **Multiple Secret Types**: Support for secrets, keys, and certificates
- **Access Control**: Azure RBAC and access policies
- **Soft Delete**: Soft delete and purge protection
- **Integration**: Integration with Azure services
- **Encryption**: Hardware Security Module (HSM) encryption

#### Configuration
```hcl
secrets = {
  mode = "azure"
  azure = {
    key_vault_name = "btp-keyvault"
    resource_group_name = "btp-resources"
    location = "East US"
    sku_name = "standard"
    
    # Access policies
    access_policies = [{
      tenant_id = "your-tenant-id"
      object_id = "your-object-id"
      key_permissions = ["Get", "List", "Create", "Delete", "Update"]
      secret_permissions = ["Get", "List", "Set", "Delete"]
      certificate_permissions = ["Get", "List", "Create", "Delete", "Update"]
    }]
    
    # Network access
    network_acls = {
      default_action = "Deny"
      bypass = "AzureServices"
      virtual_network_subnet_ids = ["/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."]
      ip_rules = ["1.2.3.4"]
    }
    
    # Soft delete and purge protection
    soft_delete_retention_days = 90
    purge_protection_enabled = true
    
    # Secrets
    secrets = [{
      name = "btp-postgres-password"
      value = "secure-postgres-password"
      content_type = "password"
      tags = {
        Environment = "production"
        Application = "btp"
      }
    }, {
      name = "btp-redis-password"
      value = "secure-redis-password"
      content_type = "password"
      tags = {
        Environment = "production"
        Application = "btp"
      }
    }]
    
    # Keys
    keys = [{
      name = "btp-encryption-key"
      key_type = "RSA"
      key_size = 2048
      key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
    }]
    
    # Certificates
    certificates = [{
      name = "btp-tls-cert"
      certificate_policy = {
        issuer_parameters = {
          name = "Self"
        }
        key_properties = {
          exportable = true
          key_size = 2048
          key_type = "RSA"
          reuse_key = true
        }
        secret_properties = {
          content_type = "application/x-pkcs12"
        }
        x509_certificate_properties = {
          key_usage = [
            "cRLSign",
            "dataEncipherment",
            "digitalSignature",
            "keyAgreement",
            "keyCertSign",
            "keyEncipherment"
          ]
          subject = "CN=btp.example.com"
          validity_in_months = 12
        }
      }
    }]
  }
}
```

#### Azure with Private Endpoint
```hcl
secrets = {
  mode = "azure"
  azure = {
    # Private endpoint configuration
    private_endpoint = {
      name = "btp-keyvault-pe"
      subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
      private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    }
    
    # Network access
    network_acls = {
      default_action = "Deny"
      bypass = "AzureServices"
    }
  }
}
```

### GCP Mode (gcp)

Deploys secrets management using Google Secret Manager managed service.

#### Features
- **Managed Service**: Fully managed secrets service
- **Automatic Rotation**: Automatic secret rotation
- **Versioning**: Secret versioning and management
- **Integration**: Integration with GCP services
- **Encryption**: Google-managed encryption
- **Access Control**: IAM-based access control

#### Configuration
```hcl
secrets = {
  mode = "gcp"
  gcp = {
    project_id = "your-project-id"
    region = "us-central1"
    
    # Secrets configuration
    secrets = [{
      name = "btp-postgres-password"
      secret_data = "secure-postgres-password"
      labels = {
        environment = "production"
        application = "btp"
      }
      
      # Automatic rotation
      rotation_config = {
        enabled = true
        rotation_period = "2592000s"  # 30 days
        next_rotation_time = "2024-02-01T00:00:00Z"
      }
    }, {
      name = "btp-redis-password"
      secret_data = "secure-redis-password"
      labels = {
        environment = "production"
        application = "btp"
      }
    }]
    
    # IAM bindings
    iam_bindings = [{
      role = "roles/secretmanager.secretAccessor"
      members = ["serviceAccount:btp-service@your-project.iam.gserviceaccount.com"]
    }, {
      role = "roles/secretmanager.secretVersionManager"
      members = ["serviceAccount:btp-admin@your-project.iam.gserviceaccount.com"]
    }]
    
    # Replication
    replication = {
      automatic = true
    }
  }
}
```

#### GCP with Regional Replication
```hcl
secrets = {
  mode = "gcp"
  gcp = {
    # Regional replication
    replication = {
      user_managed = {
        replicas = [{
          location = "us-central1"
          customer_managed_encryption = {
            kms_key_name = "projects/your-project/locations/us-central1/keyRings/btp-ring/cryptoKeys/btp-key"
          }
        }, {
          location = "us-east1"
          customer_managed_encryption = {
            kms_key_name = "projects/your-project/locations/us-east1/keyRings/btp-ring/cryptoKeys/btp-key"
          }
        }]
      }
    }
  }
}
```

### BYO Mode (byo)

Connects to an existing secrets management service.

#### Features
- **External Service**: Connect to existing secrets service
- **Flexible Configuration**: Support for various secrets services
- **Network Integration**: Works with any network-accessible service
- **Custom Authentication**: Support for custom authentication methods

#### Configuration
```hcl
secrets = {
  mode = "byo"
  byo = {
    endpoint = "https://vault.yourcompany.com"
    token = "your-vault-token"
    namespace = "btp"
    engine = "secret"
    
    # Admin credentials for management
    admin_token = "admin-vault-token"
    
    # Authentication configuration
    auth_config = {
      method = "token"
      token = "your-vault-token"
    }
    
    # TLS configuration
    tls_config = {
      enabled = true
      ca_cert = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
      client_cert = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
      client_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
    }
  }
}
```

#### HashiCorp Vault Configuration (BYO)
```hcl
secrets = {
  mode = "byo"
  byo = {
    endpoint = "https://vault.yourcompany.com"
    token = "your-vault-token"
    namespace = "btp"
    engine = "secret"
    
    admin_token = "admin-vault-token"
    
    # Vault specific configuration
    auth_config = {
      method = "kubernetes"
      kubernetes = {
        role = "btp-role"
        mount_path = "kubernetes"
      }
    }
    
    # Secrets engines
    secrets_engines = [{
      path = "secret"
      type = "kv-v2"
    }, {
      path = "pki"
      type = "pki"
    }]
  }
}
```

#### AWS Secrets Manager Configuration (BYO)
```hcl
secrets = {
  mode = "byo"
  byo = {
    endpoint = "https://secretsmanager.us-east-1.amazonaws.com"
    region = "us-east-1"
    
    # AWS credentials
    access_key = "your-aws-access-key"
    secret_key = "your-aws-secret-key"
    
    # Secrets configuration
    secrets = [{
      name = "btp-postgres-password"
      region = "us-east-1"
    }, {
      name = "btp-redis-password"
      region = "us-east-1"
    }]
  }
}
```

## Output Variables

### Normalized Outputs

The module provides consistent outputs regardless of the deployment mode:

```hcl
output "endpoint" {
  description = "Secrets management endpoint URL"
  value       = local.endpoint
}

output "token" {
  description = "Secrets management access token"
  value       = local.token
  sensitive   = true
}

output "namespace" {
  description = "Secrets management namespace"
  value       = local.namespace
}

output "engine" {
  description = "Secrets management engine/path"
  value       = local.engine
}

output "admin_token" {
  description = "Secrets management admin token"
  value       = local.admin_token
  sensitive   = true
}
```

### Output Values by Mode

| Mode | Endpoint | Namespace | Engine | Token Type |
|------|----------|-----------|--------|------------|
| **k8s** | `https://vault.btp.example.com` | `btp` | `secret` | Vault Token |
| **aws** | `https://secretsmanager.us-east-1.amazonaws.com` | `us-east-1` | `secrets` | AWS Credentials |
| **azure** | `https://btp-keyvault.vault.azure.net` | `btp-keyvault` | `secrets` | Azure Token |
| **gcp** | `https://secretmanager.googleapis.com` | `your-project-id` | `secrets` | GCP Token |
| **byo** | `https://vault.yourcompany.com` | `btp` | `secret` | Custom Token |

## Security Considerations

### Network Security

#### Kubernetes Mode
```yaml
# Network Policy Example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-network-policy
  namespace: btp-deps
spec:
  podSelector:
    matchLabels:
      app: vault
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: settlemint
    ports:
    - protocol: TCP
      port: 8200
```

#### Managed Services
- **AWS**: VPC isolation, security groups, encrypted storage
- **Azure**: VNet integration, private endpoints, encrypted storage
- **GCP**: VPC-native connectivity, private IP, encrypted storage

### Authentication and Authorization

#### Vault Authentication
```bash
# Enable Kubernetes authentication
vault auth enable kubernetes
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"

# Create Kubernetes role
vault write auth/kubernetes/role/btp-role \
  bound_service_account_names=btp-service \
  bound_service_account_namespaces=settlemint \
  policies=btp-policy \
  ttl=1h
```

#### Access Policies
```bash
# Create Vault policy
vault policy write btp-policy - <<EOF
path "secret/data/btp/*" {
  capabilities = ["read"]
}

path "secret/metadata/btp/*" {
  capabilities = ["list"]
}
EOF
```

### Encryption

#### At Rest
- **Kubernetes**: Use encrypted storage classes
- **AWS**: KMS encryption at rest
- **Azure**: Key Vault encryption at rest
- **GCP**: Secret Manager encryption at rest

#### In Transit
- **All Modes**: TLS encryption for all connections
- **Certificate Management**: Automated certificate rotation

## Performance Optimization

### Caching Strategies

#### Vault Caching
```hcl
secrets = {
  mode = "k8s"
  k8s = {
    # Enable Vault caching
    values = {
      server = {
        extraEnvironmentVars = {
          VAULT_CACHE_SIZE = "1000"
          VAULT_CACHE_TTL = "300s"
        }
      }
    }
  }
}
```

#### Connection Pooling
```hcl
secrets = {
  mode = "k8s"
  k8s = {
    # Connection pooling configuration
    values = {
      server = {
        extraEnvironmentVars = {
          VAULT_MAX_CONNECTIONS = "100"
          VAULT_MAX_IDLE_CONNECTIONS = "10"
        }
      }
    }
  }
}
```

## Monitoring and Observability

### Metrics Collection

#### Kubernetes Mode
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault-monitor
  namespace: btp-deps
spec:
  selector:
    matchLabels:
      app: vault
  endpoints:
  - port: http
    path: /v1/sys/metrics
```

#### Key Metrics to Monitor
- **Active Connections**: `vault_active_connections`
- **Request Rate**: `vault_requests_total`
- **Error Rate**: `vault_errors_total`
- **Response Time**: `vault_request_duration_seconds`
- **Secret Access**: `vault_secret_access_total`

### Health Checks

#### Kubernetes Mode
```yaml
# Liveness and Readiness Probes
livenessProbe:
  httpGet:
    path: /v1/sys/health
    port: 8200
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /v1/sys/health
    port: 8200
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### Custom Health Checks
```bash
# Check Vault health
curl -f https://vault.btp.example.com/v1/sys/health

# Check Vault status
curl -f https://vault.btp.example.com/v1/sys/status

# Check secrets access
vault kv get secret/btp/test
```

## Backup and Recovery

### Backup Strategies

#### Kubernetes Mode
```yaml
# Backup CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vault-backup
  namespace: btp-deps
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: vault-backup
            image: vault:1.15.0
            command:
            - /bin/bash
            - -c
            - |
              vault operator raft snapshot save /backup/vault-$(date +%Y%m%d).snapshot
            env:
            - name: VAULT_ADDR
              value: "https://vault.btp-deps.svc.cluster.local:8200"
            - name: VAULT_TOKEN
              valueFrom:
                secretKeyRef:
                  name: vault
                  key: root-token
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: vault-backup-pvc
```

#### Managed Services
- **AWS**: Secrets Manager backup and restore
- **Azure**: Key Vault backup and restore
- **GCP**: Secret Manager backup and restore

### Recovery Procedures

#### Point-in-Time Recovery
```bash
# Vault snapshot recovery
vault operator raft snapshot restore /backup/vault-20240101.snapshot

# AWS Secrets Manager recovery
aws secretsmanager restore-secret --secret-id btp-postgres-password --recovery-window-in-days 30

# Azure Key Vault recovery
az keyvault secret restore --vault-name btp-keyvault --file backup-secret.json

# GCP Secret Manager recovery
gcloud secrets versions access latest --secret=btp-postgres-password > recovered-secret.txt
```

## Troubleshooting

### Common Issues

#### Connection Issues
```bash
# Test Vault connectivity
kubectl run vault-test --rm -i --tty --image vault:1.15.0 -- \
  vault status -address=https://vault.btp-deps.svc.cluster.local:8200

# Test secrets access
kubectl run vault-test --rm -i --tty --image vault:1.15.0 -- \
  vault kv get secret/btp/test

# Check network connectivity
kubectl run network-test --rm -i --tty --image busybox -- \
  nc -zv vault.btp-deps.svc.cluster.local 8200
```

#### Authentication Issues
```bash
# Check Vault authentication
vault auth list

# Check token status
vault token lookup

# Check policies
vault policy list
vault policy read btp-policy
```

#### Performance Issues
```bash
# Check Vault status
vault status

# Check Vault metrics
curl https://vault.btp.example.com/v1/sys/metrics

# Check Vault logs
kubectl logs -n btp-deps deployment/vault
```

### Debug Commands

#### Kubernetes Mode
```bash
# Check Vault logs
kubectl logs -n btp-deps deployment/vault

# Check Vault status
kubectl exec -n btp-deps deployment/vault -- vault status

# Check Vault configuration
kubectl exec -n btp-deps deployment/vault -- vault read -field=value sys/config/ui
```

#### Managed Services
```bash
# AWS Secrets Manager
aws secretsmanager describe-secret --secret-id btp-postgres-password
aws secretsmanager get-secret-value --secret-id btp-postgres-password

# Azure Key Vault
az keyvault secret show --vault-name btp-keyvault --name btp-postgres-password
az keyvault secret list --vault-name btp-keyvault

# GCP Secret Manager
gcloud secrets describe btp-postgres-password
gcloud secrets versions list btp-postgres-password
```

## Best Practices

### 1. **Security**
- Use strong authentication and authorization
- Implement proper access policies
- Enable audit logging
- Regular security updates and patches

### 2. **Performance**
- Enable caching for better performance
- Use connection pooling
- Monitor and optimize request patterns
- Implement proper backup strategies

### 3. **High Availability**
- Use multiple replicas for Kubernetes deployments
- Implement proper backup strategies
- Test recovery procedures regularly
- Monitor replication lag and health

### 4. **Monitoring**
- Set up comprehensive monitoring and alerting
- Monitor key performance metrics
- Track secret access patterns
- Regular health checks

### 5. **Secret Management**
- Implement proper secret lifecycle management
- Use appropriate secret rotation policies
- Regular secret access reviews
- Implement proper secret naming conventions

## Next Steps

- [Observability Module](17-observability-module.md) - Observability stack module documentation
- [Operations Guide](18-operations.md) - Day-to-day operations
- [Security Guide](19-security.md) - Security best practices
- [Troubleshooting Guide](20-troubleshooting.md) - Common issues and solutions

---

*This Secrets module documentation provides comprehensive guidance for deploying and managing secrets across all supported platforms and deployment modes. The three-mode pattern ensures consistency while providing flexibility for different deployment scenarios.*
