# Operations Guide

## Overview

This guide provides comprehensive operational procedures for managing the SettleMint BTP platform deployed using the Universal Terraform project. It covers day-to-day operations, monitoring, maintenance, scaling, and troubleshooting.

## Table of Contents

- [Daily Operations](#daily-operations)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Maintenance Procedures](#maintenance-procedures)
- [Scaling Operations](#scaling-operations)
- [Backup and Recovery](#backup-and-recovery)
- [Security Operations](#security-operations)
- [Troubleshooting](#troubleshooting)
- [Performance Optimization](#performance-optimization)

## Daily Operations

### Health Checks

#### Automated Health Checks
```bash
#!/bin/bash
# Daily health check script
set -e

echo "=== BTP Platform Health Check ==="
echo "Date: $(date)"
echo ""

# Check Kubernetes cluster
echo "1. Kubernetes Cluster Status"
kubectl get nodes
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)"

# Check BTP platform
echo "2. BTP Platform Status"
kubectl get pods -n settlemint
kubectl get svc -n settlemint

# Check dependencies
echo "3. Dependencies Status"
kubectl get pods -n btp-deps
kubectl get svc -n btp-deps

# Check ingress
echo "4. Ingress Status"
kubectl get ingress -A

# Check certificates
echo "5. Certificate Status"
kubectl get certificates -A

# Check storage
echo "6. Storage Status"
kubectl get pv,pvc -A

echo "=== Health Check Complete ==="
```

#### Manual Health Checks
```bash
# Check platform accessibility
curl -f https://btp.example.com/health

# Check API endpoints
curl -f https://api.btp.example.com/health

# Check database connectivity
kubectl exec -n btp-deps deployment/postgres -- pg_isready -h localhost -p 5432

# Check Redis connectivity
kubectl exec -n btp-deps deployment/redis -- redis-cli ping

# Check MinIO connectivity
kubectl exec -n btp-deps deployment/minio -- mc ls local

# Check Vault connectivity
kubectl exec -n btp-deps deployment/vault -- vault status

# Check Keycloak connectivity
curl -f https://auth.btp.example.com/realms/btp/.well-known/openid_configuration
```

### Log Monitoring

#### Application Logs
```bash
# View BTP platform logs
kubectl logs -n settlemint deployment/btp-platform --tail=100 -f

# View dependency logs
kubectl logs -n btp-deps deployment/postgres --tail=50
kubectl logs -n btp-deps deployment/redis --tail=50
kubectl logs -n btp-deps deployment/minio --tail=50
kubectl logs -n btp-deps deployment/vault --tail=50
kubectl logs -n btp-deps deployment/keycloak --tail=50

# View ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100

# View cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=50
```

#### Error Log Analysis
```bash
# Search for errors in logs
kubectl logs -n settlemint deployment/btp-platform | grep -i error
kubectl logs -n btp-deps deployment/postgres | grep -i error
kubectl logs -n btp-deps deployment/redis | grep -i error

# Search for warnings
kubectl logs -n settlemint deployment/btp-platform | grep -i warning
kubectl logs -n btp-deps deployment/minio | grep -i warning

# Search for specific patterns
kubectl logs -n settlemint deployment/btp-platform | grep -E "(timeout|connection refused|permission denied)"
```

### Resource Monitoring

#### Resource Usage
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# Check specific namespaces
kubectl top pods -n settlemint
kubectl top pods -n btp-deps

# Check persistent volume usage
kubectl get pv,pvc -A -o wide
```

#### Storage Monitoring
```bash
# Check storage usage
kubectl exec -n btp-deps deployment/postgres -- df -h
kubectl exec -n btp-deps deployment/minio -- df -h
kubectl exec -n btp-deps deployment/vault -- df -h

# Check database size
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT pg_size_pretty(pg_database_size('btp'));"

# Check MinIO usage
kubectl exec -n btp-deps deployment/minio -- mc du local/btp-artifacts
```

## Monitoring and Alerting

### Prometheus Monitoring

#### Key Metrics to Monitor
```yaml
# Critical metrics for alerting
- name: btp-cpu-usage
  expr: rate(container_cpu_usage_seconds_total{namespace="settlemint"}[5m]) * 100
  threshold: 80

- name: btp-memory-usage
  expr: container_memory_usage_bytes{namespace="settlemint"} / container_spec_memory_limit_bytes * 100
  threshold: 85

- name: btp-disk-usage
  expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
  threshold: 90

- name: btp-pod-restarts
  expr: rate(kube_pod_container_status_restarts_total{namespace="settlemint"}[15m])
  threshold: 0.1

- name: btp-http-errors
  expr: rate(http_requests_total{namespace="settlemint",status=~"5.."}[5m])
  threshold: 0.01
```

#### Custom Dashboards
```json
{
  "dashboard": {
    "title": "BTP Platform Overview",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{namespace=\"settlemint\"}[5m]) * 100",
            "legendFormat": "CPU Usage %"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{namespace=\"settlemint\"} / container_spec_memory_limit_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ]
      },
      {
        "title": "HTTP Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{namespace=\"settlemint\"}[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      }
    ]
  }
}
```

### Alerting Rules

#### Critical Alerts
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: btp-critical-alerts
  namespace: btp-deps
spec:
  groups:
  - name: btp.critical
    rules:
    - alert: BTPPlatformDown
      expr: up{job="btp-platform"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "BTP Platform is down"
        description: "BTP Platform has been down for more than 1 minute"

    - alert: BTPHighCPUUsage
      expr: rate(container_cpu_usage_seconds_total{namespace="settlemint"}[5m]) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage in BTP Platform"
        description: "CPU usage is above 80% for more than 5 minutes"

    - alert: BTPHighMemoryUsage
      expr: container_memory_usage_bytes{namespace="settlemint"} / container_spec_memory_limit_bytes * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage in BTP Platform"
        description: "Memory usage is above 85% for more than 5 minutes"

    - alert: BTPDatabaseDown
      expr: up{job="postgres"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "PostgreSQL database is down"
        description: "PostgreSQL database has been down for more than 1 minute"

    - alert: BTPRedisDown
      expr: up{job="redis"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Redis is down"
        description: "Redis has been down for more than 1 minute"
```

#### Warning Alerts
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: btp-warning-alerts
  namespace: btp-deps
spec:
  groups:
  - name: btp.warning
    rules:
    - alert: BTPPodRestarting
      expr: rate(kube_pod_container_status_restarts_total{namespace="settlemint"}[15m]) > 0.1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "BTP Pod is restarting frequently"
        description: "Pod {{ $labels.pod }} is restarting more than 0.1 times per minute"

    - alert: BTPHighErrorRate
      expr: rate(http_requests_total{namespace="settlemint",status=~"5.."}[5m]) > 0.01
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in BTP Platform"
        description: "Error rate is above 1% for more than 5 minutes"

    - alert: BTPDiskSpaceLow
      expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Low disk space on node"
        description: "Disk space usage is above 90% on node {{ $labels.instance }}"
```

### Notification Channels

#### Slack Integration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack
  namespace: btp-deps
type: Opaque
stringData:
  slack_url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
---
apiVersion: monitoring.coreos.com/v1
kind: AlertmanagerConfig
metadata:
  name: btp-alertmanager-config
  namespace: btp-deps
spec:
  route:
    groupBy: ['alertname']
    groupWait: 10s
    groupInterval: 10s
    repeatInterval: 1h
    receiver: 'slack-notifications'
  receivers:
  - name: 'slack-notifications'
    slackConfigs:
    - apiURL:
        name: alertmanager-slack
        key: slack_url
      channel: '#btp-alerts'
      title: 'BTP Platform Alert'
      text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

#### Email Integration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-smtp
  namespace: btp-deps
type: Opaque
stringData:
  smtp_auth_username: "alerts@btp.example.com"
  smtp_auth_password: "smtp-password"
---
apiVersion: monitoring.coreos.com/v1
kind: AlertmanagerConfig
metadata:
  name: btp-alertmanager-config
  namespace: btp-deps
spec:
  route:
    groupBy: ['alertname']
    groupWait: 10s
    groupInterval: 10s
    repeatInterval: 1h
    receiver: 'email-notifications'
  receivers:
  - name: 'email-notifications'
    emailConfigs:
    - to: 'admin@btp.example.com'
      from: 'alerts@btp.example.com'
      smarthost: 'smtp.gmail.com:587'
      authUsername:
        name: alertmanager-smtp
        key: smtp_auth_username
      authPassword:
        name: alertmanager-smtp
        key: smtp_auth_password
      subject: 'BTP Platform Alert: {{ .GroupLabels.alertname }}'
      html: |
        <h2>BTP Platform Alert</h2>
        <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
        <p><strong>Summary:</strong> {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}</p>
        <p><strong>Description:</strong> {{ range .Alerts }}{{ .Annotations.description }}{{ end }}</p>
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Weekly Tasks
```bash
#!/bin/bash
# Weekly maintenance script
set -e

echo "=== Weekly BTP Platform Maintenance ==="
echo "Date: $(date)"
echo ""

# 1. Update system packages
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Clean up old Docker images
echo "2. Cleaning up old Docker images..."
docker system prune -f

# 3. Clean up old Kubernetes resources
echo "3. Cleaning up old Kubernetes resources..."
kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces
kubectl delete pods --field-selector=status.phase=Failed --all-namespaces

# 4. Check certificate expiration
echo "4. Checking certificate expiration..."
kubectl get certificates -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.status.notAfter}{"\n"}{end}' | while read name namespace expiry; do
  if [ -n "$expiry" ]; then
    expiry_date=$(date -d "$expiry" +%s)
    current_date=$(date +%s)
    days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
    if [ $days_until_expiry -lt 30 ]; then
      echo "WARNING: Certificate $name in namespace $namespace expires in $days_until_expiry days"
    fi
  fi
done

# 5. Database maintenance
echo "5. Performing database maintenance..."
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "VACUUM ANALYZE;"

# 6. Check storage usage
echo "6. Checking storage usage..."
kubectl get pv,pvc -A -o wide

echo "=== Weekly Maintenance Complete ==="
```

#### Monthly Tasks
```bash
#!/bin/bash
# Monthly maintenance script
set -e

echo "=== Monthly BTP Platform Maintenance ==="
echo "Date: $(date)"
echo ""

# 1. Update Helm charts
echo "1. Updating Helm charts..."
helm repo update
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack -n btp-deps
helm upgrade grafana grafana/grafana -n btp-deps
helm upgrade loki grafana/loki -n btp-deps

# 2. Update container images
echo "2. Updating container images..."
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:latest -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint

# 3. Database backup
echo "3. Creating database backup..."
kubectl exec -n btp-deps deployment/postgres -- pg_dump -U btp_user -d btp > /tmp/btp-db-backup-$(date +%Y%m%d).sql

# 4. MinIO backup
echo "4. Creating MinIO backup..."
kubectl exec -n btp-deps deployment/minio -- mc mirror local/btp-artifacts /backup/btp-artifacts-$(date +%Y%m%d)

# 5. Vault backup
echo "5. Creating Vault backup..."
kubectl exec -n btp-deps deployment/vault -- vault operator raft snapshot save /backup/vault-$(date +%Y%m%d).snapshot

# 6. Clean up old backups
echo "6. Cleaning up old backups..."
find /backup -name "*.sql" -mtime +30 -delete
find /backup -name "*.snapshot" -mtime +30 -delete

echo "=== Monthly Maintenance Complete ==="
```

### Update Procedures

#### Platform Updates
```bash
# Update BTP platform
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:v2.1.0 -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint

# Rollback if needed
kubectl rollout undo deployment/btp-platform -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint
```

#### Dependency Updates
```bash
# Update PostgreSQL
helm upgrade postgres bitnami/postgresql -n btp-deps --set image.tag=15.4

# Update Redis
helm upgrade redis bitnami/redis -n btp-deps --set image.tag=7.2

# Update MinIO
helm upgrade minio bitnami/minio -n btp-deps --set image.tag=RELEASE.2024-01-01T00-00-00Z

# Update Vault
helm upgrade vault hashicorp/vault -n btp-deps --set image.tag=1.15.0

# Update Keycloak
helm upgrade keycloak bitnami/keycloak -n btp-deps --set image.tag=23.0.0
```

#### Kubernetes Updates
```bash
# Update Kubernetes cluster (AWS EKS)
aws eks update-cluster-version --name btp-cluster --kubernetes-version 1.28

# Update Kubernetes cluster (Azure AKS)
az aks upgrade --resource-group btp-resources --name btp-cluster --kubernetes-version 1.28

# Update Kubernetes cluster (GCP GKE)
gcloud container clusters upgrade btp-cluster --cluster-version=1.28 --zone=us-central1-a
```

### Security Updates

#### Container Image Updates
```bash
# Scan for vulnerabilities
kubectl run trivy-scanner --rm -i --tty --image aquasec/trivy -- \
  trivy image settlemint/btp-platform:latest

# Update base images
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:latest -n settlemint
```

#### Certificate Updates
```bash
# Check certificate expiration
kubectl get certificates -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.status.notAfter}{"\n"}{end}'

# Force certificate renewal
kubectl annotate certificate btp-tls -n settlemint cert-manager.io/renew-before="24h" --overwrite
```

## Scaling Operations

### Horizontal Scaling

#### Application Scaling
```bash
# Scale BTP platform
kubectl scale deployment btp-platform --replicas=5 -n settlemint

# Scale dependencies
kubectl scale deployment postgres --replicas=3 -n btp-deps
kubectl scale deployment redis --replicas=3 -n btp-deps
kubectl scale deployment minio --replicas=3 -n btp-deps
kubectl scale deployment vault --replicas=3 -n btp-deps
kubectl scale deployment keycloak --replicas=3 -n btp-deps
```

#### Auto Scaling
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
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Scaling

#### Resource Updates
```bash
# Update CPU and memory limits
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"requests":{"cpu":"500m","memory":"512Mi"},"limits":{"cpu":"1000m","memory":"1Gi"}}}]}}}}'
```

#### Storage Scaling
```bash
# Expand persistent volumes
kubectl patch pvc postgres-pvc -n btp-deps -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
kubectl patch pvc minio-pvc -n btp-deps -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'
kubectl patch pvc vault-pvc -n btp-deps -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

### Cluster Scaling

#### Node Scaling
```bash
# Scale EKS cluster
aws eks update-nodegroup-config --cluster-name btp-cluster --nodegroup-name btp-nodes --scaling-config minSize=3,maxSize=10,desiredSize=5

# Scale AKS cluster
az aks scale --resource-group btp-resources --name btp-cluster --node-count 5

# Scale GKE cluster
gcloud container clusters resize btp-cluster --num-nodes=5 --zone=us-central1-a
```

## Backup and Recovery

### Backup Procedures

#### Automated Backup Script
```bash
#!/bin/bash
# Automated backup script
set -e

BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "=== Starting BTP Platform Backup ==="
echo "Date: $(date)"
echo "Backup Directory: $BACKUP_DIR"
echo ""

# 1. Database backup
echo "1. Backing up PostgreSQL database..."
kubectl exec -n btp-deps deployment/postgres -- pg_dump -U btp_user -d btp > "$BACKUP_DIR/btp-database.sql"

# 2. MinIO backup
echo "2. Backing up MinIO data..."
kubectl exec -n btp-deps deployment/minio -- mc mirror local/btp-artifacts "$BACKUP_DIR/minio-data"

# 3. Vault backup
echo "3. Backing up Vault data..."
kubectl exec -n btp-deps deployment/vault -- vault operator raft snapshot save "$BACKUP_DIR/vault.snapshot"

# 4. Keycloak backup
echo "4. Backing up Keycloak configuration..."
kubectl exec -n btp-deps deployment/keycloak -- kcadm.sh get realms/btp > "$BACKUP_DIR/keycloak-realm.json"

# 5. Kubernetes resources backup
echo "5. Backing up Kubernetes resources..."
kubectl get all -A -o yaml > "$BACKUP_DIR/kubernetes-resources.yaml"
kubectl get secrets -A -o yaml > "$BACKUP_DIR/kubernetes-secrets.yaml"
kubectl get configmaps -A -o yaml > "$BACKUP_DIR/kubernetes-configmaps.yaml"

# 6. Terraform state backup
echo "6. Backing up Terraform state..."
if [ -f "terraform.tfstate" ]; then
  cp terraform.tfstate "$BACKUP_DIR/terraform.tfstate"
fi

# 7. Compress backup
echo "7. Compressing backup..."
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "=== Backup Complete ==="
echo "Backup file: $BACKUP_DIR.tar.gz"
```

#### Cloud Backup Integration
```bash
# AWS S3 backup
aws s3 cp "$BACKUP_DIR.tar.gz" s3://btp-backups/daily/

# Azure Blob backup
az storage blob upload --file "$BACKUP_DIR.tar.gz" --container-name btp-backups --name "daily/$BACKUP_DIR.tar.gz"

# GCP Cloud Storage backup
gsutil cp "$BACKUP_DIR.tar.gz" gs://btp-backups/daily/
```

### Recovery Procedures

#### Full Recovery
```bash
#!/bin/bash
# Full recovery script
set -e

BACKUP_FILE="$1"
if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup-file.tar.gz>"
  exit 1
fi

echo "=== Starting BTP Platform Recovery ==="
echo "Date: $(date)"
echo "Backup File: $BACKUP_FILE"
echo ""

# Extract backup
echo "1. Extracting backup..."
tar -xzf "$BACKUP_FILE"
BACKUP_DIR=$(basename "$BACKUP_FILE" .tar.gz)

# 2. Restore Kubernetes resources
echo "2. Restoring Kubernetes resources..."
kubectl apply -f "$BACKUP_DIR/kubernetes-resources.yaml"
kubectl apply -f "$BACKUP_DIR/kubernetes-secrets.yaml"
kubectl apply -f "$BACKUP_DIR/kubernetes-configmaps.yaml"

# 3. Wait for pods to be ready
echo "3. Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=minio -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=vault -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=keycloak -n btp-deps --timeout=300s

# 4. Restore database
echo "4. Restoring PostgreSQL database..."
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp < "$BACKUP_DIR/btp-database.sql"

# 5. Restore MinIO data
echo "5. Restoring MinIO data..."
kubectl exec -n btp-deps deployment/minio -- mc mirror "$BACKUP_DIR/minio-data" local/btp-artifacts

# 6. Restore Vault data
echo "6. Restoring Vault data..."
kubectl exec -n btp-deps deployment/vault -- vault operator raft snapshot restore "$BACKUP_DIR/vault.snapshot"

# 7. Restore Keycloak configuration
echo "7. Restoring Keycloak configuration..."
kubectl exec -n btp-deps deployment/keycloak -- kcadm.sh create realms -f "$BACKUP_DIR/keycloak-realm.json"

# 8. Restart BTP platform
echo "8. Restarting BTP platform..."
kubectl rollout restart deployment/btp-platform -n settlemint
kubectl rollout status deployment/btp-platform -n settlemint

echo "=== Recovery Complete ==="
```

#### Partial Recovery
```bash
# Restore only database
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp < backup/btp-database.sql

# Restore only MinIO data
kubectl exec -n btp-deps deployment/minio -- mc mirror backup/minio-data local/btp-artifacts

# Restore only Vault data
kubectl exec -n btp-deps deployment/vault -- vault operator raft snapshot restore backup/vault.snapshot
```

## Security Operations

### Security Monitoring

#### Security Scanning
```bash
# Container vulnerability scanning
kubectl run trivy-scanner --rm -i --tty --image aquasec/trivy -- \
  trivy image settlemint/btp-platform:latest

# Kubernetes security scanning
kubectl run kube-score --rm -i --tty --image zegl/kube-score -- \
  kube-score score /tmp/kubernetes-resources.yaml

# Network policy validation
kubectl run network-policy-validator --rm -i --tty --image weaveworks/network-policy-validator -- \
  network-policy-validator validate
```

#### Access Review
```bash
# Review RBAC permissions
kubectl get clusterroles,roles,clusterrolebindings,rolebindings -A

# Review service accounts
kubectl get serviceaccounts -A

# Review secrets
kubectl get secrets -A

# Review network policies
kubectl get networkpolicies -A
```

### Security Updates

#### Certificate Rotation
```bash
# Force certificate renewal
kubectl annotate certificate btp-tls -n settlemint cert-manager.io/renew-before="24h" --overwrite

# Check certificate status
kubectl get certificates -A
```

#### Secret Rotation
```bash
# Rotate database passwords
kubectl create secret generic postgres-secret \
  --from-literal=password=new-secure-password \
  --dry-run=client -o yaml | kubectl apply -f -

# Rotate API keys
kubectl create secret generic btp-api-keys \
  --from-literal=api-key=new-api-key \
  --dry-run=client -o yaml | kubectl apply -f -

# Rotate JWT signing keys
kubectl create secret generic jwt-signing-key \
  --from-literal=signing-key=new-jwt-signing-key \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Troubleshooting

### Common Issues

#### Pod Issues
```bash
# Check pod status
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)"

# Check pod logs
kubectl logs -n settlemint deployment/btp-platform --previous

# Check pod events
kubectl describe pod -n settlemint deployment/btp-platform

# Check pod resources
kubectl top pods -n settlemint
```

#### Network Issues
```bash
# Check service endpoints
kubectl get endpoints -A

# Check ingress status
kubectl get ingress -A

# Check network policies
kubectl get networkpolicies -A

# Test connectivity
kubectl run network-test --rm -i --tty --image busybox -- \
  nc -zv postgres.btp-deps.svc.cluster.local 5432
```

#### Storage Issues
```bash
# Check persistent volumes
kubectl get pv,pvc -A

# Check storage classes
kubectl get storageclass

# Check volume attachments
kubectl get volumeattachments
```

### Debug Procedures

#### Application Debug
```bash
# Enable debug logging
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","env":[{"name":"LOG_LEVEL","value":"DEBUG"}]}]}}}}'

# Check application metrics
kubectl exec -n settlemint deployment/btp-platform -- curl localhost:8080/metrics

# Check application health
kubectl exec -n settlemint deployment/btp-platform -- curl localhost:8080/health
```

#### Database Debug
```bash
# Check database connections
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT * FROM pg_stat_activity;"

# Check database size
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT pg_size_pretty(pg_database_size('btp'));"

# Check slow queries
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

#### Redis Debug
```bash
# Check Redis info
kubectl exec -n btp-deps deployment/redis -- redis-cli info

# Check Redis memory usage
kubectl exec -n btp-deps deployment/redis -- redis-cli info memory

# Check Redis slow log
kubectl exec -n btp-deps deployment/redis -- redis-cli slowlog get 10
```

## Performance Optimization

### Application Performance

#### Resource Optimization
```bash
# Update resource requests and limits
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"requests":{"cpu":"500m","memory":"512Mi"},"limits":{"cpu":"1000m","memory":"1Gi"}}}]}}}}'
```

#### Database Optimization
```bash
# Optimize PostgreSQL configuration
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "ALTER SYSTEM SET shared_buffers = '256MB';"
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "ALTER SYSTEM SET effective_cache_size = '1GB';"
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT pg_reload_conf();"
```

#### Cache Optimization
```bash
# Optimize Redis configuration
kubectl exec -n btp-deps deployment/redis -- redis-cli CONFIG SET maxmemory 512mb
kubectl exec -n btp-deps deployment/redis -- redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Infrastructure Performance

#### Node Optimization
```bash
# Check node resources
kubectl top nodes

# Check node capacity
kubectl describe nodes

# Check node events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Storage Optimization
```bash
# Check storage performance
kubectl exec -n btp-deps deployment/postgres -- iostat -x 1 5

# Check storage usage
kubectl exec -n btp-deps deployment/postgres -- df -h
```

## Next Steps

- [Security Guide](19-security.md) - Security best practices
- [Troubleshooting Guide](20-troubleshooting.md) - Common issues and solutions
- [Advanced Configuration](21-advanced-configuration.md) - Advanced configuration options
- [API Reference](22-api-reference.md) - API documentation

---

*This Operations Guide provides comprehensive procedures for managing the SettleMint BTP platform in production. Regular execution of these procedures ensures platform stability, security, and performance.*
