# Advanced Configuration

## Overview

This guide covers advanced configuration options for the SettleMint BTP platform deployed using the Universal Terraform project. It includes custom configurations, performance tuning, high availability setups, and enterprise-grade configurations.

## Table of Contents

- [Custom Configurations](#custom-configurations)
- [Performance Tuning](#performance-tuning)
- [High Availability](#high-availability)
- [Enterprise Configurations](#enterprise-configurations)
- [Custom Modules](#custom-modules)
- [Advanced Networking](#advanced-networking)
- [Monitoring & Observability](#monitoring--observability)
- [Security Hardening](#security-hardening)

## Custom Configurations

### Custom Terraform Variables

#### Advanced Variable Configuration
```hcl
# variables-advanced.tf
variable "custom_configurations" {
  description = "Custom configuration options"
  type = object({
    # Performance tuning
    performance = object({
      enable_hpa = bool
      min_replicas = number
      max_replicas = number
      target_cpu_utilization = number
      target_memory_utilization = number
    })
    
    # High availability
    high_availability = object({
      enable_multi_az = bool
      enable_cross_region = bool
      backup_retention_days = number
      enable_automated_backups = bool
    })
    
    # Security
    security = object({
      enable_network_policies = bool
      enable_pod_security_policies = bool
      enable_rbac = bool
      enable_audit_logging = bool
    })
    
    # Monitoring
    monitoring = object({
      enable_prometheus = bool
      enable_grafana = bool
      enable_loki = bool
      enable_jaeger = bool
      retention_days = number
    })
    
    # Custom resources
    custom_resources = object({
      enable_custom_dashboard = bool
      enable_custom_alerts = bool
      enable_custom_webhooks = bool
    })
  })
  
  default = {
    performance = {
      enable_hpa = true
      min_replicas = 2
      max_replicas = 10
      target_cpu_utilization = 70
      target_memory_utilization = 80
    }
    
    high_availability = {
      enable_multi_az = true
      enable_cross_region = false
      backup_retention_days = 30
      enable_automated_backups = true
    }
    
    security = {
      enable_network_policies = true
      enable_pod_security_policies = true
      enable_rbac = true
      enable_audit_logging = true
    }
    
    monitoring = {
      enable_prometheus = true
      enable_grafana = true
      enable_loki = true
      enable_jaeger = false
      retention_days = 30
    }
    
    custom_resources = {
      enable_custom_dashboard = true
      enable_custom_alerts = true
      enable_custom_webhooks = true
    }
  }
}
```

#### Environment-Specific Configurations
```hcl
# environments/production.tfvars
platform = "aws"
environment = "production"

# Performance settings
custom_configurations = {
  performance = {
    enable_hpa = true
    min_replicas = 3
    max_replicas = 20
    target_cpu_utilization = 60
    target_memory_utilization = 70
  }
  
  high_availability = {
    enable_multi_az = true
    enable_cross_region = true
    backup_retention_days = 90
    enable_automated_backups = true
  }
  
  security = {
    enable_network_policies = true
    enable_pod_security_policies = true
    enable_rbac = true
    enable_audit_logging = true
  }
}

# Resource sizing
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu = "2000m"
      }
    }
  }
}

# Dependencies with high availability
postgres = {
  mode = "aws"
  aws = {
    multi_az = true
    backup_retention_period = 30
    performance_insights_enabled = true
    monitoring_interval = 60
  }
}

redis = {
  mode = "aws"
  aws = {
    num_cache_clusters = 3
    automatic_failover_enabled = true
    multi_az = true
  }
}
```

```hcl
# environments/staging.tfvars
platform = "aws"
environment = "staging"

# Performance settings
custom_configurations = {
  performance = {
    enable_hpa = true
    min_replicas = 1
    max_replicas = 5
    target_cpu_utilization = 80
    target_memory_utilization = 85
  }
  
  high_availability = {
    enable_multi_az = false
    enable_cross_region = false
    backup_retention_days = 7
    enable_automated_backups = true
  }
}

# Resource sizing
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "512Mi"
        cpu = "500m"
      }
      limits = {
        memory = "1Gi"
        cpu = "1000m"
      }
    }
  }
}
```

### Custom Helm Values

#### BTP Platform Custom Values
```yaml
# custom-values/btp-platform.yaml
btp:
  enabled: true
  values:
    # Application configuration
    app:
      name: "btp-platform"
      version: "latest"
      environment: "production"
      
    # Resource configuration
    resources:
      requests:
        memory: "1Gi"
        cpu: "1000m"
      limits:
        memory: "2Gi"
        cpu: "2000m"
    
    # Autoscaling
    autoscaling:
      enabled: true
      minReplicas: 3
      maxReplicas: 20
      targetCPUUtilizationPercentage: 60
      targetMemoryUtilizationPercentage: 70
    
    # Environment variables
    env:
      - name: LOG_LEVEL
        value: "info"
      - name: METRICS_ENABLED
        value: "true"
      - name: HEALTH_CHECK_ENABLED
        value: "true"
      - name: CORS_ENABLED
        value: "true"
      - name: CORS_ALLOWED_ORIGINS
        value: "https://btp.example.com,https://app.btp.example.com"
    
    # Database configuration
    database:
      host: "postgres.btp-deps.svc.cluster.local"
      port: 5432
      name: "btp"
      username: "btp_user"
      password: "${POSTGRES_PASSWORD}"
      sslMode: "require"
      maxConnections: 100
      connectionTimeout: 30
      idleTimeout: 600
      maxLifetime: 3600
    
    # Redis configuration
    redis:
      host: "redis.btp-deps.svc.cluster.local"
      port: 6379
      password: "${REDIS_PASSWORD}"
      db: 0
      maxRetries: 3
      poolSize: 10
      minIdleConns: 5
      maxConnAge: 3600
      poolTimeout: 30
      idleTimeout: 300
      idleCheckFrequency: 60
    
    # Object storage configuration
    objectStorage:
      endpoint: "https://minio.btp-deps.svc.cluster.local:9000"
      bucket: "btp-artifacts"
      accessKey: "${MINIO_ACCESS_KEY}"
      secretKey: "${MINIO_SECRET_KEY}"
      region: "us-east-1"
      useSSL: true
      pathStyle: true
    
    # Vault configuration
    vault:
      endpoint: "https://vault.btp-deps.svc.cluster.local:8200"
      token: "${VAULT_TOKEN}"
      namespace: "btp"
      engine: "secret"
    
    # OAuth configuration
    oauth:
      issuer: "https://auth.btp.example.com/realms/btp"
      clientId: "btp-client"
      clientSecret: "${OAUTH_CLIENT_SECRET}"
      realm: "btp"
    
    # Monitoring configuration
    monitoring:
      prometheus:
        enabled: true
        port: 9090
        path: "/metrics"
      grafana:
        enabled: true
        dashboard: "btp-platform"
    
    # Security configuration
    security:
      cors:
        allowedOrigins: ["https://btp.example.com"]
        allowedMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allowedHeaders: ["Authorization", "Content-Type"]
        allowCredentials: true
        maxAge: 3600
      
      rateLimit:
        enabled: true
        requestsPerMinute: 1000
        burstSize: 100
      
      jwt:
        issuer: "https://auth.btp.example.com/realms/btp"
        audience: "btp-client"
        algorithm: "RS256"
        expiresIn: "1h"
        refreshExpiresIn: "24h"
```

#### Dependency Custom Values
```yaml
# custom-values/dependencies.yaml
postgres:
  mode: "k8s"
  k8s:
    values:
      # High availability configuration
      architecture: "replication"
      replicaCount: 3
      
      # Resource configuration
      primary:
        resources:
          requests:
            memory: "1Gi"
            cpu: "1000m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
      
      # Persistence configuration
      persistence:
        enabled: true
        size: "100Gi"
        storageClass: "gp2"
        accessModes:
          - ReadWriteOnce
      
      # Configuration
      postgresql:
        postgresqlDatabase: "btp"
        postgresqlUsername: "btp_user"
        postgresqlPassword: "${POSTGRES_PASSWORD}"
        
        # Performance tuning
        postgresqlConfiguration: |
          # Connection settings
          max_connections = 200
          shared_buffers = 256MB
          effective_cache_size = 1GB
          maintenance_work_mem = 64MB
          checkpoint_completion_target = 0.9
          wal_buffers = 16MB
          default_statistics_target = 100
          
          # Logging
          log_destination = 'stderr'
          logging_collector = on
          log_directory = 'pg_log'
          log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
          log_statement = 'all'
          log_min_duration_statement = 1000
          
          # Replication
          wal_level = replica
          max_wal_senders = 3
          max_replication_slots = 3
          hot_standby = on

redis:
  mode: "k8s"
  k8s:
    values:
      # High availability configuration
      architecture: "replication"
      replicaCount: 3
      
      # Resource configuration
      master:
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
      
      # Persistence configuration
      persistence:
        enabled: true
        size: "50Gi"
        storageClass: "gp2"
      
      # Configuration
      auth:
        enabled: true
        password: "${REDIS_PASSWORD}"
      
      # Performance tuning
      configuration: |
        # Memory management
        maxmemory 512mb
        maxmemory-policy allkeys-lru
        maxmemory-samples 5
        
        # Persistence
        save 900 1
        save 300 10
        save 60 10000
        stop-writes-on-bgsave-error yes
        rdbcompression yes
        rdbchecksum yes
        
        # Logging
        loglevel notice
        logfile ""
        
        # Network
        timeout 300
        tcp-keepalive 60
        
        # Security
        protected-mode yes
        requirepass ${REDIS_PASSWORD}

minio:
  mode: "k8s"
  k8s:
    values:
      # High availability configuration
      mode: "distributed"
      replicas: 4
      
      # Resource configuration
      resources:
        requests:
          memory: "512Mi"
          cpu: "500m"
        limits:
          memory: "1Gi"
          cpu: "1000m"
      
      # Persistence configuration
      persistence:
        enabled: true
        size: "200Gi"
        storageClass: "gp2"
      
      # Configuration
      auth:
        rootUser: "minioadmin"
        rootPassword: "${MINIO_ROOT_PASSWORD}"
      
      # Performance tuning
      configuration: |
        # Storage
        MINIO_BROWSER_REDIRECT_URL=https://minio.btp.example.com
        MINIO_SERVER_URL=https://minio.btp.example.com
        
        # Performance
        MINIO_API_REQUESTS_MAX=1000
        MINIO_API_REQUESTS_DEADLINE=10s
        
        # Security
        MINIO_BROWSER=off
        
        # Logging
        MINIO_LOG_LEVEL=INFO
```

## Performance Tuning

### Application Performance

#### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: btp-platform-hpa
  namespace: settlemint
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: btp-platform
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

#### Vertical Pod Autoscaler
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: btp-platform-vpa
  namespace: settlemint
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: btp-platform
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: btp-platform
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2000m
        memory: 4Gi
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits
```

#### Custom Metrics
```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: btp-platform-metrics
  namespace: settlemint
spec:
  selector:
    matchLabels:
      app: btp-platform
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: btp-platform-custom-metrics
  namespace: settlemint
spec:
  groups:
  - name: btp-platform.custom
    rules:
    - record: btp_platform_requests_per_second
      expr: rate(http_requests_total[5m])
    - record: btp_platform_response_time_p95
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
    - record: btp_platform_error_rate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

### Database Performance

#### PostgreSQL Performance Tuning
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-performance-config
  namespace: btp-deps
data:
  postgresql.conf: |
    # Connection settings
    max_connections = 200
    shared_buffers = 256MB
    effective_cache_size = 1GB
    maintenance_work_mem = 64MB
    checkpoint_completion_target = 0.9
    wal_buffers = 16MB
    default_statistics_target = 100
    
    # Query planning
    random_page_cost = 1.1
    effective_io_concurrency = 200
    work_mem = 4MB
    
    # Background writer
    bgwriter_delay = 200ms
    bgwriter_lru_maxpages = 100
    bgwriter_lru_multiplier = 2.0
    
    # Checkpoints
    checkpoint_timeout = 5min
    max_wal_size = 1GB
    min_wal_size = 80MB
    
    # Logging
    log_destination = 'stderr'
    logging_collector = on
    log_directory = 'pg_log'
    log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
    log_statement = 'all'
    log_min_duration_statement = 1000
    log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
    
    # Replication
    wal_level = replica
    max_wal_senders = 3
    max_replication_slots = 3
    hot_standby = on
    hot_standby_feedback = on
    
    # Autovacuum
    autovacuum = on
    autovacuum_max_workers = 3
    autovacuum_naptime = 1min
    autovacuum_vacuum_threshold = 50
    autovacuum_analyze_threshold = 50
    autovacuum_vacuum_scale_factor = 0.2
    autovacuum_analyze_scale_factor = 0.1
```

#### Redis Performance Tuning
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-performance-config
  namespace: btp-deps
data:
  redis.conf: |
    # Memory management
    maxmemory 1gb
    maxmemory-policy allkeys-lru
    maxmemory-samples 5
    
    # Persistence
    save 900 1
    save 300 10
    save 60 10000
    stop-writes-on-bgsave-error yes
    rdbcompression yes
    rdbchecksum yes
    
    # AOF
    appendonly yes
    appendfsync everysec
    no-appendfsync-on-rewrite no
    auto-aof-rewrite-percentage 100
    auto-aof-rewrite-min-size 64mb
    
    # Network
    timeout 300
    tcp-keepalive 60
    tcp-backlog 511
    
    # Performance
    hz 10
    dynamic-hz yes
    
    # Logging
    loglevel notice
    logfile ""
    
    # Security
    protected-mode yes
    requirepass ${REDIS_PASSWORD}
```

### Storage Performance

#### High-Performance Storage Class
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: high-performance
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ultra-high-performance
provisioner: ebs.csi.aws.com
parameters:
  type: io2
  iops: "10000"
  encrypted: "true"
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
```

## High Availability

### Multi-AZ Deployment

#### AWS Multi-AZ Configuration
```hcl
# AWS Multi-AZ configuration
module "btp_ha" {
  source = "./modules/aws-ha"
  
  # Multi-AZ configuration
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # EKS cluster with multiple node groups
  eks_cluster = {
    version = "1.28"
    node_groups = {
      main = {
        instance_types = ["t3.large"]
        min_size = 2
        max_size = 10
        desired_size = 3
        availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      }
      spot = {
        instance_types = ["t3.large"]
        min_size = 0
        max_size = 5
        desired_size = 2
        availability_zones = ["us-east-1a", "us-east-1b"]
        spot = true
      }
    }
  }
  
  # RDS Multi-AZ
  rds = {
    multi_az = true
    backup_retention_period = 30
    backup_window = "03:00-04:00"
    maintenance_window = "sun:04:00-sun:05:00"
    performance_insights_enabled = true
    monitoring_interval = 60
  }
  
  # ElastiCache Multi-AZ
  elasticache = {
    num_cache_clusters = 3
    automatic_failover_enabled = true
    multi_az = true
    snapshot_retention_limit = 5
    snapshot_window = "03:00-05:00"
  }
  
  # S3 Cross-Region Replication
  s3_replication = {
    enabled = true
    destination_region = "us-west-2"
    destination_bucket = "btp-artifacts-backup"
  }
}
```

#### Kubernetes High Availability
```yaml
# High availability deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: btp-platform-ha
  namespace: settlemint
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: btp-platform
  template:
    metadata:
      labels:
        app: btp-platform
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - btp-platform
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: node-type
                operator: In
                values:
                - compute
      containers:
      - name: btp-platform
        image: settlemint/btp-platform:latest
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        resources:
          requests:
            memory: "1Gi"
            cpu: "1000m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
```

### Cross-Region Deployment

#### Cross-Region Configuration
```hcl
# Cross-region deployment
module "btp_cross_region" {
  source = "./modules/cross-region"
  
  # Primary region
  primary_region = "us-east-1"
  primary_availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Secondary region
  secondary_region = "us-west-2"
  secondary_availability_zones = ["us-west-2a", "us-west-2b"]
  
  # Cross-region replication
  replication = {
    enabled = true
    regions = ["us-west-2"]
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/87654321-4321-4321-4321-210987654321"
  }
  
  # Global load balancer
  global_load_balancer = {
    enabled = true
    health_check_path = "/health"
    health_check_interval = 30
    health_check_timeout = 5
    health_check_healthy_threshold = 2
    health_check_unhealthy_threshold = 5
  }
}
```

## Enterprise Configurations

### Multi-Tenant Setup

#### Tenant Isolation
```yaml
# Tenant namespace
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-1
  labels:
    tenant: "tenant-1"
    pod-security.kubernetes.io/enforce: restricted
---
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-2
  labels:
    tenant: "tenant-2"
    pod-security.kubernetes.io/enforce: restricted
---
# Tenant-specific network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
  namespace: tenant-1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-1
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-1
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

#### Resource Quotas
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-1-quota
  namespace: tenant-1
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "10"
    pods: "20"
    services: "5"
    secrets: "10"
    configmaps: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: tenant-1-limits
  namespace: tenant-1
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "2000m"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
```

### Compliance Configuration

#### CIS Kubernetes Benchmark
```yaml
# CIS-compliant configuration
apiVersion: v1
kind: Namespace
metadata:
  name: settlemint
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: cis-compliant-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
```

#### Audit Logging
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: kube-system
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: Metadata
      namespaces: ["settlemint", "btp-deps"]
      verbs: ["create", "update", "patch", "delete"]
    - level: Request
      namespaces: ["settlemint", "btp-deps"]
      verbs: ["get", "list", "watch"]
    - level: RequestResponse
      resources:
      - group: ""
        resources: ["secrets", "configmaps"]
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    - level: Metadata
      resources:
      - group: "apps"
        resources: ["deployments", "replicasets", "statefulsets"]
    - level: Metadata
      resources:
      - group: "networking.k8s.io"
        resources: ["networkpolicies"]
    - level: Metadata
      resources:
      - group: "policy"
        resources: ["podsecuritypolicies"]
```

## Custom Modules

### Custom BTP Module

#### Custom BTP Configuration
```hcl
# modules/custom-btp/main.tf
resource "helm_release" "custom_btp" {
  count = var.enabled ? 1 : 0
  
  name       = var.release_name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  
  create_namespace = true
  
  values = [
    yamlencode({
      # Custom application configuration
      app = {
        name = var.app_name
        version = var.app_version
        environment = var.environment
        
        # Custom features
        features = {
          enableCustomDashboard = var.enable_custom_dashboard
          enableCustomAPI = var.enable_custom_api
          enableCustomWebhooks = var.enable_custom_webhooks
        }
      }
      
      # Custom resource configuration
      resources = var.resources
      
      # Custom environment variables
      env = var.custom_env_vars
      
      # Custom configuration
      config = var.custom_config
      
      # Custom ingress configuration
      ingress = {
        enabled = var.ingress_enabled
        hosts = var.ingress_hosts
        tls = var.ingress_tls
        annotations = var.ingress_annotations
      }
    })
  ]
  
  depends_on = var.dependencies
}
```

#### Custom Module Variables
```hcl
# modules/custom-btp/variables.tf
variable "enabled" {
  description = "Whether to enable the custom BTP module"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "custom-btp"
}

variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://charts.settlemint.com"
}

variable "chart_name" {
  description = "Name of the Helm chart"
  type        = string
  default     = "btp-platform"
}

variable "chart_version" {
  description = "Version of the Helm chart"
  type        = string
  default     = "1.0.0"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "settlemint"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "custom-btp"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "latest"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "enable_custom_dashboard" {
  description = "Enable custom dashboard"
  type        = bool
  default     = false
}

variable "enable_custom_api" {
  description = "Enable custom API"
  type        = bool
  default     = false
}

variable "enable_custom_webhooks" {
  description = "Enable custom webhooks"
  type        = bool
  default     = false
}

variable "resources" {
  description = "Resource configuration"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "custom_env_vars" {
  description = "Custom environment variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "custom_config" {
  description = "Custom configuration"
  type        = map(string)
  default     = {}
}

variable "ingress_enabled" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "ingress_hosts" {
  description = "Ingress hosts"
  type        = list(string)
  default     = []
}

variable "ingress_tls" {
  description = "Ingress TLS configuration"
  type = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default = []
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default     = {}
}

variable "dependencies" {
  description = "Module dependencies"
  type        = list(string)
  default     = []
}
```

### Custom Monitoring Module

#### Custom Monitoring Configuration
```hcl
# modules/custom-monitoring/main.tf
resource "helm_release" "custom_prometheus" {
  count = var.enable_prometheus ? 1 : 0
  
  name       = "custom-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = var.monitoring_namespace
  
  create_namespace = true
  
  values = [
    yamlencode({
      # Custom Prometheus configuration
      prometheus = {
        prometheusSpec = {
          # Custom retention
          retention = var.retention_period
          retentionSize = var.retention_size
          
          # Custom resources
          resources = var.prometheus_resources
          
          # Custom storage
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.storage_size
                  }
                }
              }
            }
          }
          
          # Custom rules
          ruleSelector = {
            matchLabels = {
              "prometheus" = "custom"
              "role" = "alert-rules"
            }
          }
          
          # Custom service monitors
          serviceMonitorSelector = {
            matchLabels = {
              "prometheus" = "custom"
            }
          }
        }
      }
      
      # Custom Grafana configuration
      grafana = {
        enabled = var.enable_grafana
        resources = var.grafana_resources
        
        # Custom dashboards
        dashboardProviders = {
          "custom-dashboard-provider.yaml" = {
            apiVersion = 1
            providers = [{
              name = "custom"
              orgId = 1
              folder = "Custom"
              type = "file"
              disableDeletion = false
              editable = true
              options = {
                path = "/var/lib/grafana/dashboards/custom"
              }
            }]
          }
        }
        
        # Custom dashboards
        dashboards = {
          custom = var.custom_dashboards
        }
      }
      
      # Custom AlertManager configuration
      alertmanager = {
        alertmanagerSpec = {
          resources = var.alertmanager_resources
          
          # Custom configuration
          configSecret = "custom-alertmanager-config"
        }
      }
    })
  ]
}
```

## Advanced Networking

### Service Mesh Configuration

#### Istio Service Mesh
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: settlemint
  labels:
    istio-injection: enabled
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: btp-platform
  namespace: settlemint
spec:
  hosts:
  - btp-platform
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: btp-platform
        subset: canary
      weight: 100
  - route:
    - destination:
        host: btp-platform
        subset: stable
      weight: 90
    - destination:
        host: btp-platform
        subset: canary
      weight: 10
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: btp-platform
  namespace: settlemint
spec:
  host: btp-platform
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    circuitBreaker:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
  - name: stable
    labels:
      version: stable
  - name: canary
    labels:
      version: canary
```

### Network Policies

#### Advanced Network Policies
```yaml
# Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: settlemint
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow BTP platform ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-btp-platform-ingress
  namespace: settlemint
spec:
  podSelector:
    matchLabels:
      app: btp-platform
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
---
# Allow BTP platform egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-btp-platform-egress
  namespace: settlemint
spec:
  podSelector:
    matchLabels:
      app: btp-platform
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: btp-deps
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 6379  # Redis
    - protocol: TCP
      port: 9000  # MinIO
    - protocol: TCP
      port: 8200  # Vault
    - protocol: TCP
      port: 8080  # Keycloak
  - to: []
    ports:
    - protocol: TCP
      port: 53    # DNS
    - protocol: UDP
      port: 53    # DNS
    - protocol: TCP
      port: 443   # HTTPS
```

## Monitoring & Observability

### Advanced Monitoring

#### Custom Metrics
```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: btp-platform-custom-metrics
  namespace: settlemint
  labels:
    prometheus: custom
spec:
  selector:
    matchLabels:
      app: btp-platform
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: btp-platform-custom-rules
  namespace: settlemint
  labels:
    prometheus: custom
    role: alert-rules
spec:
  groups:
  - name: btp-platform.custom
    rules:
    - record: btp_platform_requests_per_second
      expr: rate(http_requests_total[5m])
    - record: btp_platform_response_time_p95
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
    - record: btp_platform_response_time_p99
      expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
    - record: btp_platform_error_rate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
    - record: btp_platform_active_connections
      expr: btp_platform_active_connections
    - record: btp_platform_database_connections
      expr: btp_platform_database_connections
    - record: btp_platform_cache_hit_rate
      expr: btp_platform_cache_hits / btp_platform_cache_requests
```

#### Custom Dashboards
```json
{
  "dashboard": {
    "title": "BTP Platform - Custom Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(btp_platform_requests_per_second[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "btp_platform_response_time_p95",
            "legendFormat": "P95 Response Time"
          },
          {
            "expr": "btp_platform_response_time_p99",
            "legendFormat": "P99 Response Time"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "btp_platform_error_rate",
            "legendFormat": "Error Rate"
          }
        ]
      },
      {
        "title": "Active Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "btp_platform_active_connections",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "btp_platform_database_connections",
            "legendFormat": "Database Connections"
          }
        ]
      },
      {
        "title": "Cache Hit Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "btp_platform_cache_hit_rate",
            "legendFormat": "Cache Hit Rate"
          }
        ]
      }
    ]
  }
}
```

### Distributed Tracing

#### Jaeger Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: jaeger-config
  namespace: btp-deps
data:
  jaeger.yaml: |
    collector:
      grpc:
        host-port: "0.0.0.0:14250"
      http:
        host-port: "0.0.0.0:14268"
    query:
      grpc:
        host-port: "0.0.0.0:16686"
    agent:
      grpc:
        host-port: "0.0.0.0:14250"
      http:
        host-port: "0.0.0.0:14268"
    storage:
      type: elasticsearch
      elasticsearch:
        server-urls: "http://elasticsearch.btp-deps.svc.cluster.local:9200"
        index-prefix: "jaeger"
        username: "jaeger"
        password: "${JAEGER_ES_PASSWORD}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: btp-deps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.45
        ports:
        - containerPort: 16686
        - containerPort: 14250
        - containerPort: 14268
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
        - name: SPAN_STORAGE_TYPE
          value: "elasticsearch"
        - name: ES_SERVER_URLS
          value: "http://elasticsearch.btp-deps.svc.cluster.local:9200"
        - name: ES_USERNAME
          value: "jaeger"
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: jaeger-secret
              key: password
```

## Security Hardening

### Advanced Security

#### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: settlemint
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

#### Security Context
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: btp-platform-secure
  namespace: settlemint
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: btp-platform
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001
          runAsGroup: 1001
          capabilities:
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache
          mountPath: /var/cache
        - name: var-log
          mountPath: /var/log
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache
        emptyDir: {}
      - name: var-log
        emptyDir: {}
```

## Next Steps

- [API Reference](22-api-reference.md) - API documentation
- [Examples](23-examples.md) - Configuration examples
- [FAQ](24-faq.md) - Frequently asked questions
- [Contributing](25-contributing.md) - Contributing guidelines

---

*This Advanced Configuration guide provides comprehensive options for customizing and optimizing the SettleMint BTP platform deployment. These configurations enable enterprise-grade deployments with high availability, performance, and security.*
