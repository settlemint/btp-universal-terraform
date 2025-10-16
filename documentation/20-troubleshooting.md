# Troubleshooting Guide

## Overview

This guide provides comprehensive troubleshooting procedures for common issues encountered when deploying and operating the SettleMint BTP platform using the Universal Terraform project. It covers diagnostic procedures, common problems, and their solutions.

## Table of Contents

- [Diagnostic Procedures](#diagnostic-procedures)
- [Common Issues](#common-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Dependency Issues](#dependency-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Security Issues](#security-issues)
- [Recovery Procedures](#recovery-procedures)

## Diagnostic Procedures

### Health Check Script

#### Comprehensive Health Check
```bash
#!/bin/bash
# Comprehensive health check script
set -e

echo "=== BTP Platform Health Check ==="
echo "Date: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    local component=$1
    local command=$2
    local expected=$3
    
    echo -n "Checking $component... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# 1. Kubernetes cluster health
echo "1. Kubernetes Cluster Health"
check_status "Kubernetes API" "kubectl cluster-info"
check_status "Nodes" "kubectl get nodes | grep -v NotReady"
check_status "System Pods" "kubectl get pods -n kube-system | grep -v Running"

# 2. BTP platform health
echo ""
echo "2. BTP Platform Health"
check_status "BTP Platform Pods" "kubectl get pods -n settlemint | grep -v Running"
check_status "BTP Platform Services" "kubectl get svc -n settlemint"
check_status "BTP Platform Ingress" "kubectl get ingress -n settlemint"

# 3. Dependencies health
echo ""
echo "3. Dependencies Health"
check_status "PostgreSQL" "kubectl get pods -n btp-deps | grep postgres | grep Running"
check_status "Redis" "kubectl get pods -n btp-deps | grep redis | grep Running"
check_status "MinIO" "kubectl get pods -n btp-deps | grep minio | grep Running"
check_status "Vault" "kubectl get pods -n btp-deps | grep vault | grep Running"
check_status "Keycloak" "kubectl get pods -n btp-deps | grep keycloak | grep Running"

# 4. Network connectivity
echo ""
echo "4. Network Connectivity"
check_status "DNS Resolution" "nslookup kubernetes.default.svc.cluster.local"
check_status "Internal Connectivity" "kubectl run test-pod --rm -i --tty --image busybox -- nslookup postgres.btp-deps.svc.cluster.local"

# 5. Storage health
echo ""
echo "5. Storage Health"
check_status "Persistent Volumes" "kubectl get pv | grep -v Bound"
check_status "Persistent Volume Claims" "kubectl get pvc -A | grep -v Bound"

# 6. Certificate health
echo ""
echo "6. Certificate Health"
check_status "Certificates" "kubectl get certificates -A | grep -v True"

# 7. Application health
echo ""
echo "7. Application Health"
check_status "BTP Platform Health Endpoint" "kubectl run test-pod --rm -i --tty --image curlimages/curl -- curl -f http://btp-platform.settlemint.svc.cluster.local:8080/health"

echo ""
echo "=== Health Check Complete ==="
```

#### Quick Health Check
```bash
#!/bin/bash
# Quick health check script
set -e

echo "=== Quick BTP Platform Health Check ==="

# Check critical components
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)" || echo "No critical pod issues found"

# Check resource usage
echo "Node resource usage:"
kubectl top nodes

echo "Pod resource usage:"
kubectl top pods -A --sort-by=memory | head -20

# Check recent events
echo "Recent events:"
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10

echo "=== Quick Health Check Complete ==="
```

### Log Analysis

#### Log Collection Script
```bash
#!/bin/bash
# Log collection script for troubleshooting
set -e

LOG_DIR="/tmp/btp-troubleshooting-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "=== Collecting BTP Platform Logs ==="
echo "Log Directory: $LOG_DIR"
echo ""

# 1. System logs
echo "1. Collecting system logs..."
kubectl get nodes -o wide > "$LOG_DIR/nodes.txt"
kubectl get pods -A -o wide > "$LOG_DIR/pods.txt"
kubectl get svc -A -o wide > "$LOG_DIR/services.txt"
kubectl get ingress -A -o wide > "$LOG_DIR/ingress.txt"

# 2. BTP platform logs
echo "2. Collecting BTP platform logs..."
kubectl logs -n settlemint deployment/btp-platform --tail=1000 > "$LOG_DIR/btp-platform.log" 2>&1 || true
kubectl describe pod -n settlemint -l app=btp-platform > "$LOG_DIR/btp-platform-describe.txt" 2>&1 || true

# 3. Dependency logs
echo "3. Collecting dependency logs..."
kubectl logs -n btp-deps deployment/postgres --tail=500 > "$LOG_DIR/postgres.log" 2>&1 || true
kubectl logs -n btp-deps deployment/redis --tail=500 > "$LOG_DIR/redis.log" 2>&1 || true
kubectl logs -n btp-deps deployment/minio --tail=500 > "$LOG_DIR/minio.log" 2>&1 || true
kubectl logs -n btp-deps deployment/vault --tail=500 > "$LOG_DIR/vault.log" 2>&1 || true
kubectl logs -n btp-deps deployment/keycloak --tail=500 > "$LOG_DIR/keycloak.log" 2>&1 || true

# 4. Ingress logs
echo "4. Collecting ingress logs..."
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=1000 > "$LOG_DIR/ingress-nginx.log" 2>&1 || true

# 5. Cert-manager logs
echo "5. Collecting cert-manager logs..."
kubectl logs -n cert-manager deployment/cert-manager --tail=500 > "$LOG_DIR/cert-manager.log" 2>&1 || true

# 6. Events
echo "6. Collecting events..."
kubectl get events -A --sort-by=.metadata.creationTimestamp > "$LOG_DIR/events.txt"

# 7. Resource usage
echo "7. Collecting resource usage..."
kubectl top nodes > "$LOG_DIR/node-resources.txt" 2>&1 || true
kubectl top pods -A > "$LOG_DIR/pod-resources.txt" 2>&1 || true

# 8. Network policies
echo "8. Collecting network policies..."
kubectl get networkpolicies -A -o yaml > "$LOG_DIR/network-policies.yaml" 2>&1 || true

# 9. Secrets and configmaps
echo "9. Collecting secrets and configmaps..."
kubectl get secrets -A -o yaml > "$LOG_DIR/secrets.yaml" 2>&1 || true
kubectl get configmaps -A -o yaml > "$LOG_DIR/configmaps.yaml" 2>&1 || true

# 10. Storage
echo "10. Collecting storage information..."
kubectl get pv,pvc -A -o wide > "$LOG_DIR/storage.txt"
kubectl get storageclass -o yaml > "$LOG_DIR/storage-classes.yaml" 2>&1 || true

# Compress logs
echo "11. Compressing logs..."
tar -czf "$LOG_DIR.tar.gz" "$LOG_DIR"
rm -rf "$LOG_DIR"

echo "=== Log Collection Complete ==="
echo "Logs saved to: $LOG_DIR.tar.gz"
```

#### Log Analysis Tools
```bash
#!/bin/bash
# Log analysis script
set -e

LOG_FILE="$1"
if [ -z "$LOG_FILE" ]; then
    echo "Usage: $0 <log-file>"
    exit 1
fi

echo "=== Analyzing Log File: $LOG_FILE ==="

# Extract errors
echo "1. Extracting errors..."
grep -i "error" "$LOG_FILE" | tail -20

# Extract warnings
echo ""
echo "2. Extracting warnings..."
grep -i "warning" "$LOG_FILE" | tail -20

# Extract connection issues
echo ""
echo "3. Extracting connection issues..."
grep -iE "(connection refused|timeout|connection reset)" "$LOG_FILE" | tail -20

# Extract authentication issues
echo ""
echo "4. Extracting authentication issues..."
grep -iE "(unauthorized|forbidden|authentication failed)" "$LOG_FILE" | tail -20

# Extract resource issues
echo ""
echo "5. Extracting resource issues..."
grep -iE "(out of memory|disk full|cpu limit)" "$LOG_FILE" | tail -20

# Extract startup issues
echo ""
echo "6. Extracting startup issues..."
grep -iE "(failed to start|startup failed|initialization failed)" "$LOG_FILE" | tail -20

echo ""
echo "=== Log Analysis Complete ==="
```

## Common Issues

### Pod Issues

#### Pod Stuck in Pending State
```bash
# Check pod status
kubectl describe pod -n settlemint <pod-name>

# Check node capacity
kubectl describe nodes

# Check resource quotas
kubectl describe quota -n settlemint

# Check persistent volume claims
kubectl get pvc -n settlemint

# Check storage classes
kubectl get storageclass
```

**Common Causes:**
- Insufficient resources on nodes
- Resource quotas exceeded
- Persistent volume claim issues
- Node selector/tolerations not matching

**Solutions:**
```bash
# Scale up cluster
kubectl scale deployment btp-platform --replicas=1 -n settlemint

# Check and fix resource quotas
kubectl patch quota -n settlemint <quota-name> -p '{"spec":{"hard":{"requests.cpu":"2","requests.memory":"4Gi"}}}'

# Check storage class
kubectl patch storageclass gp2 -p '{"allowVolumeExpansion":true}'
```

#### Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -n settlemint <pod-name> --previous

# Check pod events
kubectl describe pod -n settlemint <pod-name>

# Check configuration
kubectl get configmap -n settlemint -o yaml

# Check secrets
kubectl get secret -n settlemint -o yaml
```

**Common Causes:**
- Configuration errors
- Missing secrets
- Database connection issues
- Resource limits exceeded

**Solutions:**
```bash
# Fix configuration
kubectl patch configmap btp-config -n settlemint -p '{"data":{"database.host":"postgres.btp-deps.svc.cluster.local"}}'

# Fix secrets
kubectl create secret generic btp-secrets -n settlemint --from-literal=password=correct-password

# Increase resource limits
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

#### ImagePullBackOff
```bash
# Check image pull secrets
kubectl get secret -n settlemint

# Check image name and tag
kubectl get deployment btp-platform -n settlemint -o jsonpath='{.spec.template.spec.containers[0].image}'

# Test image pull
docker pull <image-name>:<tag>
```

**Common Causes:**
- Invalid image name or tag
- Missing image pull secrets
- Network connectivity issues
- Registry authentication issues

**Solutions:**
```bash
# Fix image name
kubectl set image deployment/btp-platform btp-platform=settlemint/btp-platform:latest -n settlemint

# Add image pull secret
kubectl create secret docker-registry regcred -n settlemint \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>

# Patch deployment to use image pull secret
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```

### Service Issues

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n settlemint

# Check service selector
kubectl get svc -n settlemint -o yaml

# Check pod labels
kubectl get pods -n settlemint --show-labels

# Test service connectivity
kubectl run test-pod --rm -i --tty --image busybox -- nslookup btp-platform.settlemint.svc.cluster.local
```

**Common Causes:**
- Service selector doesn't match pod labels
- Pods not running
- Network policies blocking traffic
- Port configuration issues

**Solutions:**
```bash
# Fix service selector
kubectl patch svc btp-platform -n settlemint -p '{"spec":{"selector":{"app":"btp-platform"}}}'

# Check and fix pod labels
kubectl label pod -n settlemint <pod-name> app=btp-platform

# Check network policies
kubectl get networkpolicies -n settlemint
```

#### Load Balancer Not Working
```bash
# Check load balancer status
kubectl get svc -n settlemint

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress -n settlemint

# Check DNS resolution
nslookup <load-balancer-ip>
```

**Common Causes:**
- Ingress controller not running
- Ingress configuration errors
- DNS configuration issues
- Firewall rules blocking traffic

**Solutions:**
```bash
# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Fix ingress configuration
kubectl patch ingress btp-ingress -n settlemint -p '{"spec":{"tls":[{"secretName":"btp-tls"}]}}'

# Check firewall rules
kubectl get networkpolicies -A
```

### Database Issues

#### PostgreSQL Connection Issues
```bash
# Check PostgreSQL pod status
kubectl get pods -n btp-deps | grep postgres

# Check PostgreSQL logs
kubectl logs -n btp-deps deployment/postgres --tail=100

# Test database connectivity
kubectl run postgres-test --rm -i --tty --image postgres:15 -- psql -h postgres.btp-deps.svc.cluster.local -U btp_user -d btp

# Check database configuration
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SHOW ALL;"
```

**Common Causes:**
- Database not ready
- Authentication issues
- Network connectivity problems
- Configuration errors

**Solutions:**
```bash
# Restart PostgreSQL
kubectl rollout restart deployment/postgres -n btp-deps

# Fix authentication
kubectl create secret generic postgres-secret -n btp-deps --from-literal=password=correct-password

# Check network policies
kubectl get networkpolicies -n btp-deps
```

#### Redis Connection Issues
```bash
# Check Redis pod status
kubectl get pods -n btp-deps | grep redis

# Check Redis logs
kubectl logs -n btp-deps deployment/redis --tail=100

# Test Redis connectivity
kubectl run redis-test --rm -i --tty --image redis:7 -- redis-cli -h redis.btp-deps.svc.cluster.local ping

# Check Redis configuration
kubectl exec -n btp-deps deployment/redis -- redis-cli CONFIG GET "*"
```

**Common Causes:**
- Redis not ready
- Authentication issues
- Memory issues
- Configuration errors

**Solutions:**
```bash
# Restart Redis
kubectl rollout restart deployment/redis -n btp-deps

# Fix authentication
kubectl create secret generic redis-secret -n btp-deps --from-literal=password=correct-password

# Check memory usage
kubectl exec -n btp-deps deployment/redis -- redis-cli INFO memory
```

### Authentication Issues

#### Keycloak Connection Issues
```bash
# Check Keycloak pod status
kubectl get pods -n btp-deps | grep keycloak

# Check Keycloak logs
kubectl logs -n btp-deps deployment/keycloak --tail=100

# Test Keycloak connectivity
kubectl run keycloak-test --rm -i --tty --image curlimages/curl -- curl -f https://auth.btp.example.com/realms/btp/.well-known/openid_configuration

# Check Keycloak configuration
kubectl exec -n btp-deps deployment/keycloak -- kcadm.sh config credentials --server https://keycloak:8080 --realm master --user admin --password $ADMIN_PASSWORD
```

**Common Causes:**
- Keycloak not ready
- Database connection issues
- Configuration errors
- Certificate issues

**Solutions:**
```bash
# Restart Keycloak
kubectl rollout restart deployment/keycloak -n btp-deps

# Fix database connection
kubectl patch configmap keycloak-config -n btp-deps -p '{"data":{"database.host":"postgres.btp-deps.svc.cluster.local"}}'

# Check certificates
kubectl get certificates -n btp-deps
```

#### JWT Token Issues
```bash
# Check JWT configuration
kubectl get configmap btp-jwt-config -n settlemint -o yaml

# Check JWT secret
kubectl get secret jwt-signing-key -n settlemint -o yaml

# Test JWT token
kubectl run jwt-test --rm -i --tty --image curlimages/curl -- curl -H "Authorization: Bearer $JWT_TOKEN" https://api.btp.example.com/health
```

**Common Causes:**
- Invalid JWT configuration
- Wrong signing key
- Token expiration
- Issuer mismatch

**Solutions:**
```bash
# Fix JWT configuration
kubectl patch configmap btp-jwt-config -n settlemint -p '{"data":{"jwt-config.yaml":"issuer: \"https://auth.btp.example.com/realms/btp\""}}'

# Fix JWT secret
kubectl create secret generic jwt-signing-key -n settlemint --from-literal=signing-key=correct-signing-key

# Restart application
kubectl rollout restart deployment/btp-platform -n settlemint
```

## Platform-Specific Issues

### AWS Issues

#### EKS Cluster Issues
```bash
# Check EKS cluster status
aws eks describe-cluster --name btp-cluster

# Check node groups
aws eks describe-nodegroup --cluster-name btp-cluster --nodegroup-name btp-nodes

# Check IAM roles
aws iam get-role --role-name btp-cluster-role
```

**Common Issues:**
- IAM role permissions
- VPC configuration
- Security group rules
- Load balancer configuration

**Solutions:**
```bash
# Fix IAM role permissions
aws iam attach-role-policy --role-name btp-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Fix VPC configuration
aws ec2 modify-vpc-attribute --vpc-id vpc-12345 --enable-dns-hostnames

# Fix security group rules
aws ec2 authorize-security-group-ingress --group-id sg-12345 --protocol tcp --port 443 --cidr 0.0.0.0/0
```

#### RDS Issues
```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier btp-postgres

# Check RDS logs
aws rds describe-db-log-files --db-instance-identifier btp-postgres

# Check RDS parameters
aws rds describe-db-parameters --db-instance-identifier btp-postgres
```

**Common Issues:**
- Connection limits
- Storage issues
- Parameter group configuration
- Security group rules

**Solutions:**
```bash
# Fix connection limits
aws rds modify-db-instance --db-instance-identifier btp-postgres --max-connections 100

# Fix storage
aws rds modify-db-instance --db-instance-identifier btp-postgres --allocated-storage 100

# Fix parameter group
aws rds modify-db-instance --db-instance-identifier btp-postgres --db-parameter-group-name btp-postgres-params
```

### Azure Issues

#### AKS Cluster Issues
```bash
# Check AKS cluster status
az aks show --resource-group btp-resources --name btp-cluster

# Check node pools
az aks nodepool list --resource-group btp-resources --cluster-name btp-cluster

# Check AKS logs
az aks diagnostics --resource-group btp-resources --name btp-cluster
```

**Common Issues:**
- Service principal permissions
- VNet configuration
- Load balancer configuration
- Storage class issues

**Solutions:**
```bash
# Fix service principal permissions
az role assignment create --assignee <service-principal-id> --role Contributor --scope /subscriptions/<subscription-id>/resourceGroups/btp-resources

# Fix VNet configuration
az network vnet subnet update --resource-group btp-resources --vnet-name btp-vnet --name btp-subnet --service-endpoints Microsoft.Storage

# Fix storage class
kubectl patch storageclass default -p '{"allowVolumeExpansion":true}'
```

#### Azure Database Issues
```bash
# Check Azure Database status
az postgres server show --resource-group btp-resources --name btp-postgres

# Check Azure Database logs
az postgres server-logs list --resource-group btp-resources --server-name btp-postgres

# Check Azure Database configuration
az postgres server configuration list --resource-group btp-resources --server-name btp-postgres
```

**Common Issues:**
- Connection limits
- Storage issues
- Firewall rules
- SSL configuration

**Solutions:**
```bash
# Fix connection limits
az postgres server configuration set --resource-group btp-resources --server-name btp-postgres --name max_connections --value 100

# Fix storage
az postgres server update --resource-group btp-resources --name btp-postgres --storage-size 100GB

# Fix firewall rules
az postgres server firewall-rule create --resource-group btp-resources --server-name btp-postgres --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

### GCP Issues

#### GKE Cluster Issues
```bash
# Check GKE cluster status
gcloud container clusters describe btp-cluster --zone=us-central1-a

# Check node pools
gcloud container node-pools list --cluster=btp-cluster --zone=us-central1-a

# Check GKE logs
gcloud logging read "resource.type=gke_cluster" --limit=100
```

**Common Issues:**
- Service account permissions
- VPC configuration
- Load balancer configuration
- Storage class issues

**Solutions:**
```bash
# Fix service account permissions
gcloud projects add-iam-policy-binding <project-id> --member="serviceAccount:<service-account>@<project-id>.iam.gserviceaccount.com" --role="roles/container.admin"

# Fix VPC configuration
gcloud compute networks subnets update btp-subnet --region=us-central1 --enable-private-ip-google-access

# Fix storage class
kubectl patch storageclass standard -p '{"allowVolumeExpansion":true}'
```

#### Cloud SQL Issues
```bash
# Check Cloud SQL instance status
gcloud sql instances describe btp-postgres

# Check Cloud SQL logs
gcloud sql operations list --instance=btp-postgres

# Check Cloud SQL configuration
gcloud sql instances describe btp-postgres --format="value(settings.databaseFlags)"
```

**Common Issues:**
- Connection limits
- Storage issues
- Authorized networks
- SSL configuration

**Solutions:**
```bash
# Fix connection limits
gcloud sql instances patch btp-postgres --database-flags=max_connections=100

# Fix storage
gcloud sql instances patch btp-postgres --storage-size=100GB

# Fix authorized networks
gcloud sql instances patch btp-postgres --authorized-networks=0.0.0.0/0
```

## Dependency Issues

### MinIO Issues

#### MinIO Connection Issues
```bash
# Check MinIO pod status
kubectl get pods -n btp-deps | grep minio

# Check MinIO logs
kubectl logs -n btp-deps deployment/minio --tail=100

# Test MinIO connectivity
kubectl run minio-test --rm -i --tty --image minio/mc -- mc alias set local http://minio.btp-deps.svc.cluster.local:9000 minioadmin minioadmin123456789012 && mc ls local
```

**Common Causes:**
- MinIO not ready
- Authentication issues
- Storage issues
- Configuration errors

**Solutions:**
```bash
# Restart MinIO
kubectl rollout restart deployment/minio -n btp-deps

# Fix authentication
kubectl create secret generic minio-secret -n btp-deps --from-literal=root-user=minioadmin --from-literal=root-password=minioadmin123456789012

# Check storage
kubectl get pvc -n btp-deps | grep minio
```

### Vault Issues

#### Vault Connection Issues
```bash
# Check Vault pod status
kubectl get pods -n btp-deps | grep vault

# Check Vault logs
kubectl logs -n btp-deps deployment/vault --tail=100

# Test Vault connectivity
kubectl run vault-test --rm -i --tty --image vault:1.15 -- vault status -address=https://vault.btp-deps.svc.cluster.local:8200
```

**Common Causes:**
- Vault not ready
- Authentication issues
- Storage backend issues
- Configuration errors

**Solutions:**
```bash
# Restart Vault
kubectl rollout restart deployment/vault -n btp-deps

# Fix authentication
kubectl create secret generic vault-secret -n btp-deps --from-literal=root-token=correct-root-token

# Check storage backend
kubectl exec -n btp-deps deployment/vault -- vault operator raft list-peers
```

## Network Issues

### DNS Resolution Issues
```bash
# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Test DNS resolution
kubectl run dns-test --rm -i --tty --image busybox -- nslookup kubernetes.default.svc.cluster.local

# Check DNS logs
kubectl logs -n kube-system deployment/coredns
```

**Common Causes:**
- CoreDNS configuration issues
- Network policies blocking DNS
- DNS server issues
- Service discovery issues

**Solutions:**
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Fix DNS configuration
kubectl patch configmap coredns -n kube-system -p '{"data":{"Corefile":".:53 {\n    errors\n    health {\n       lameduck 5s\n    }\n    ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n       pods insecure\n       fallthrough in-addr.arpa ip6.arpa\n       ttl 30\n    }\n    prometheus :9153\n    forward . /etc/resolv.conf {\n       max_concurrent 1000\n    }\n    cache 30\n    loop\n    reload\n    loadbalance\n}"}}'

# Check network policies
kubectl get networkpolicies -A
```

### Network Policy Issues
```bash
# Check network policies
kubectl get networkpolicies -A

# Check network policy configuration
kubectl describe networkpolicy -n settlemint

# Test network connectivity
kubectl run network-test --rm -i --tty --image busybox -- nc -zv postgres.btp-deps.svc.cluster.local 5432
```

**Common Causes:**
- Network policy blocking traffic
- Incorrect selector configuration
- Missing ingress/egress rules
- Namespace selector issues

**Solutions:**
```bash
# Fix network policy
kubectl patch networkpolicy btp-network-policy -n settlemint -p '{"spec":{"ingress":[{"from":[{"namespaceSelector":{"matchLabels":{"name":"btp-deps"}}}]}]}}'

# Delete network policy for testing
kubectl delete networkpolicy btp-network-policy -n settlemint
```

## Performance Issues

### High CPU Usage
```bash
# Check CPU usage
kubectl top pods -A --sort-by=cpu

# Check node CPU usage
kubectl top nodes

# Check pod resource limits
kubectl describe pod -n settlemint <pod-name>
```

**Common Causes:**
- Insufficient resource limits
- Inefficient code
- High traffic load
- Resource leaks

**Solutions:**
```bash
# Increase CPU limits
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"limits":{"cpu":"1000m"}}}]}}}}'

# Scale horizontally
kubectl scale deployment btp-platform --replicas=3 -n settlemint

# Check for resource leaks
kubectl exec -n settlemint deployment/btp-platform -- ps aux
```

### High Memory Usage
```bash
# Check memory usage
kubectl top pods -A --sort-by=memory

# Check node memory usage
kubectl top nodes

# Check pod memory limits
kubectl describe pod -n settlemint <pod-name>
```

**Common Causes:**
- Memory leaks
- Insufficient memory limits
- Large data processing
- Inefficient memory usage

**Solutions:**
```bash
# Increase memory limits
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"limits":{"memory":"2Gi"}}}]}}}}'

# Check for memory leaks
kubectl exec -n settlemint deployment/btp-platform -- free -h

# Restart pod to clear memory
kubectl delete pod -n settlemint -l app=btp-platform
```

### Slow Response Times
```bash
# Check application metrics
kubectl exec -n settlemint deployment/btp-platform -- curl localhost:8080/metrics

# Check database performance
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Check Redis performance
kubectl exec -n btp-deps deployment/redis -- redis-cli --latency-history
```

**Common Causes:**
- Database performance issues
- Network latency
- Resource constraints
- Inefficient queries

**Solutions:**
```bash
# Optimize database
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "VACUUM ANALYZE;"

# Check network latency
kubectl run network-test --rm -i --tty --image busybox -- ping -c 10 postgres.btp-deps.svc.cluster.local

# Scale resources
kubectl patch deployment btp-platform -n settlemint -p '{"spec":{"template":{"spec":{"containers":[{"name":"btp-platform","resources":{"requests":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
```

## Security Issues

### Certificate Issues
```bash
# Check certificate status
kubectl get certificates -A

# Check certificate details
kubectl describe certificate -n settlemint btp-tls

# Check certificate expiration
kubectl get certificates -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.status.notAfter}{"\n"}{end}'
```

**Common Causes:**
- Certificate expiration
- DNS validation issues
- Let's Encrypt rate limits
- Certificate configuration errors

**Solutions:**
```bash
# Force certificate renewal
kubectl annotate certificate btp-tls -n settlemint cert-manager.io/renew-before="24h" --overwrite

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Fix DNS validation
kubectl patch certificate btp-tls -n settlemint -p '{"spec":{"dnsNames":["btp.example.com"]}}'
```

### Authentication Issues
```bash
# Check authentication logs
kubectl logs -n settlemint deployment/btp-platform | grep -i auth

# Check JWT configuration
kubectl get configmap btp-jwt-config -n settlemint -o yaml

# Test authentication
kubectl run auth-test --rm -i --tty --image curlimages/curl -- curl -H "Authorization: Bearer $JWT_TOKEN" https://api.btp.example.com/health
```

**Common Causes:**
- Invalid JWT tokens
- Authentication service issues
- Configuration errors
- Network connectivity issues

**Solutions:**
```bash
# Fix JWT configuration
kubectl patch configmap btp-jwt-config -n settlemint -p '{"data":{"jwt-config.yaml":"issuer: \"https://auth.btp.example.com/realms/btp\""}}'

# Restart authentication service
kubectl rollout restart deployment/keycloak -n btp-deps

# Check network connectivity
kubectl run network-test --rm -i --tty --image busybox -- nc -zv auth.btp.example.com 443
```

## Recovery Procedures

### Complete Platform Recovery
```bash
#!/bin/bash
# Complete platform recovery script
set -e

echo "=== BTP Platform Recovery ==="
echo "Date: $(date)"
echo ""

# 1. Check cluster health
echo "1. Checking cluster health..."
kubectl get nodes
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)"

# 2. Restart failed deployments
echo "2. Restarting failed deployments..."
kubectl rollout restart deployment/btp-platform -n settlemint
kubectl rollout restart deployment/postgres -n btp-deps
kubectl rollout restart deployment/redis -n btp-deps
kubectl rollout restart deployment/minio -n btp-deps
kubectl rollout restart deployment/vault -n btp-deps
kubectl rollout restart deployment/keycloak -n btp-deps

# 3. Wait for deployments to be ready
echo "3. Waiting for deployments to be ready..."
kubectl wait --for=condition=ready pod -l app=btp-platform -n settlemint --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=minio -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=vault -n btp-deps --timeout=300s
kubectl wait --for=condition=ready pod -l app=keycloak -n btp-deps --timeout=300s

# 4. Verify connectivity
echo "4. Verifying connectivity..."
kubectl run connectivity-test --rm -i --tty --image busybox -- nc -zv postgres.btp-deps.svc.cluster.local 5432
kubectl run connectivity-test --rm -i --tty --image busybox -- nc -zv redis.btp-deps.svc.cluster.local 6379
kubectl run connectivity-test --rm -i --tty --image busybox -- nc -zv minio.btp-deps.svc.cluster.local 9000
kubectl run connectivity-test --rm -i --tty --image busybox -- nc -zv vault.btp-deps.svc.cluster.local 8200
kubectl run connectivity-test --rm -i --tty --image busybox -- nc -zv keycloak.btp-deps.svc.cluster.local 8080

# 5. Test application health
echo "5. Testing application health..."
kubectl run health-test --rm -i --tty --image curlimages/curl -- curl -f https://btp.example.com/health

echo "=== Recovery Complete ==="
```

### Partial Recovery
```bash
#!/bin/bash
# Partial recovery script for specific components
set -e

COMPONENT="$1"
if [ -z "$COMPONENT" ]; then
    echo "Usage: $0 <component>"
    echo "Components: btp-platform, postgres, redis, minio, vault, keycloak"
    exit 1
fi

echo "=== Recovering $COMPONENT ==="
echo "Date: $(date)"
echo ""

case "$COMPONENT" in
    "btp-platform")
        echo "Recovering BTP Platform..."
        kubectl rollout restart deployment/btp-platform -n settlemint
        kubectl wait --for=condition=ready pod -l app=btp-platform -n settlemint --timeout=300s
        ;;
    "postgres")
        echo "Recovering PostgreSQL..."
        kubectl rollout restart deployment/postgres -n btp-deps
        kubectl wait --for=condition=ready pod -l app=postgres -n btp-deps --timeout=300s
        ;;
    "redis")
        echo "Recovering Redis..."
        kubectl rollout restart deployment/redis -n btp-deps
        kubectl wait --for=condition=ready pod -l app=redis -n btp-deps --timeout=300s
        ;;
    "minio")
        echo "Recovering MinIO..."
        kubectl rollout restart deployment/minio -n btp-deps
        kubectl wait --for=condition=ready pod -l app=minio -n btp-deps --timeout=300s
        ;;
    "vault")
        echo "Recovering Vault..."
        kubectl rollout restart deployment/vault -n btp-deps
        kubectl wait --for=condition=ready pod -l app=vault -n btp-deps --timeout=300s
        ;;
    "keycloak")
        echo "Recovering Keycloak..."
        kubectl rollout restart deployment/keycloak -n btp-deps
        kubectl wait --for=condition=ready pod -l app=keycloak -n btp-deps --timeout=300s
        ;;
    *)
        echo "Unknown component: $COMPONENT"
        exit 1
        ;;
esac

echo "=== Recovery Complete ==="
```

## Next Steps

- [Advanced Configuration](21-advanced-configuration.md) - Advanced configuration options
- [API Reference](22-api-reference.md) - API documentation
- [Examples](23-examples.md) - Configuration examples
- [FAQ](24-faq.md) - Frequently asked questions

---

*This Troubleshooting Guide provides comprehensive procedures for diagnosing and resolving common issues with the SettleMint BTP platform. Regular use of these procedures ensures quick resolution of problems and maintains platform stability.*
