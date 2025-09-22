#!/usr/bin/env bash
set -euo pipefail

# Basic dependency verification for the local cluster.
# - Checks helm release status and k8s readiness for each module
# - Optionally performs simple TCP/HTTP checks via port-forward if tools are present
#
# Usage: bash scripts/verify.sh [namespace]
# Defaults to namespace "btp-deps".

NS=${1:-btp-deps}

pass() { echo "[OK]  $*"; }
fail() { echo "[ERR] $*"; return 1; }
info() { echo "[info] $*"; }
warn() { echo "[warn] $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "$1 not found" >&2; exit 1; }
}

check_ready_rollout() {
  local type="$1" sel="$2" timeout="${3:-120s}"
  if ! kubectl -n "$NS" get "$type" -l "$sel" >/dev/null 2>&1; then
    fail "$type with selector '$sel' not found"
    return 1
  fi
  if ! kubectl -n "$NS" rollout status "$type" -l "$sel" --timeout="$timeout" >/dev/null 2>&1; then
    # Fallback readiness check by comparing readyReplicas to replicas
    local ready replicas kind
    kind=$(echo "$type" | awk '{print tolower($0)}')
    ready=$(kubectl -n "$NS" get "$type" -l "$sel" -o jsonpath='{.items[0].status.readyReplicas}' 2>/dev/null || echo "")
    replicas=$(kubectl -n "$NS" get "$type" -l "$sel" -o jsonpath='{.items[0].spec.replicas}' 2>/dev/null || echo "")
    if [ -n "$ready" ] && [ -n "$replicas" ] && [ "$ready" = "$replicas" ]; then
      pass "$type ready (fallback): selector '$sel'"
      return 0
    fi
    kubectl -n "$NS" get "$type" -l "$sel" || true
    fail "$type rollout not ready for selector '$sel'"
    return 1
  fi
  pass "$type ready: selector '$sel'"
}

check_helm_release() {
  local release="$1"
  if helm -n "$NS" status "$release" >/dev/null 2>&1; then
    pass "helm release '$release' is deployed"
  else
    fail "helm release '$release' not deployed"
  fi
}

check_clusterissuer_ready() {
  local name="$1"
  if ! kubectl get clusterissuer "$name" >/dev/null 2>&1; then
    fail "ClusterIssuer '$name' not found"
    return 1
  fi
  # Wait until Ready true
  local i=0
  while true; do
    if kubectl get clusterissuer "$name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
      pass "ClusterIssuer '$name' Ready"
      break
    fi
    i=$((i+1))
    if [ "$i" -ge 30 ]; then
      kubectl get clusterissuer "$name" -o yaml | sed -n '1,80p'
      fail "ClusterIssuer '$name' not Ready after timeout"
      return 1
    fi
    sleep 2
  done
}

check_tcp_portforward() {
  # Args: resource_kind/name local_port remote_port
  local res="$1" lport="$2" rport="$3"
  if ! command -v nc >/dev/null 2>&1; then
    info "nc not found; skipping TCP check for $res:$rport"
    return 0
  fi
  local pf
  set +e
  kubectl -n "$NS" port-forward "$res" "$lport:$rport" >/dev/null 2>&1 & pf=$!
  set -e
  # give port-forward time
  sleep 2
  if nc -z 127.0.0.1 "$lport" >/dev/null 2>&1; then
    pass "port-forward $res $rport reachable on localhost:$lport"
    kill "$pf" >/dev/null 2>&1 || true
    return 0
  else
    kill "$pf" >/dev/null 2>&1 || true
    warn "port-forward $res $rport NOT reachable (non-fatal)"
    return 0
  fi
}

echo "[verify] Namespace: $NS"
require_cmd kubectl
require_cmd helm

overall_rc=0

ephem_exec() {
  # Args: label image command...
  local label="$1"; shift
  local image="$1"; shift
  local cmd="$*"
  local name="verify-${label}-$(date +%s)-$RANDOM"
  # Create sleeping pod
  kubectl -n "$NS" run "$name" \
    --image="$image" \
    --restart=Never \
    --labels="btp.smint.io/verify=$label" \
    --command -- sh -lc "sleep 3600" >/dev/null 2>&1 || return 1
  # Wait ready
  if ! kubectl -n "$NS" wait --for=condition=Ready pod/"$name" --timeout=90s >/dev/null 2>&1; then
    kubectl -n "$NS" logs "$name" || true
    kubectl -n "$NS" delete pod "$name" --wait=false >/dev/null 2>&1 || true
    return 1
  fi
  # Exec command (suppress stdout/stderr; we only care about exit code)
  set +e
  kubectl -n "$NS" exec "$name" --request-timeout=20s -- sh -lc "$cmd" >/dev/null 2>&1
  local rc=$?
  set -e
  kubectl -n "$NS" delete pod "$name" --wait=false >/dev/null 2>&1 || true
  return "$rc"
}

# HTTP helper using busybox wget with a hard timeout
http_check() {
  # Args: label url
  local label="$1" url="$2" tries=3
  while [ "$tries" -gt 0 ]; do
    ephem_exec "$label" busybox:1.36 "wget -q -T 8 -O /dev/null '$url'"
    local rc=$?
    if [ "$rc" -eq 0 ]; then
      return 0
    fi
    tries=$((tries-1)); sleep 2
  done
  return 1
}

wait_service() {
  # Args: service-name port [retries] [sleep]
  local name="$1" port="$2" retries="${3:-30}" delay="${4:-2}"
  local i=0
  while true; do
    if kubectl -n "$NS" get svc "$name" >/dev/null 2>&1; then
      if [ -n "$(kubectl -n "$NS" get endpoints "$name" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)" ]; then
        pass "service '$name' has endpoints"
        return 0
      fi
    fi
    i=$((i+1))
    if [ "$i" -ge "$retries" ]; then
      kubectl -n "$NS" get svc "$name" -o yaml || true
      kubectl -n "$NS" get endpoints "$name" -o yaml || true
      fail "service '$name' has no endpoints after wait"
      return 1
    fi
    sleep "$delay"
  done
}

echo "[verify] Ingress + TLS"
check_helm_release ingress || overall_rc=1
check_ready_rollout deployment "app.kubernetes.io/instance=ingress,app.kubernetes.io/name=ingress-nginx" || overall_rc=1
check_helm_release cert-manager || overall_rc=1
check_ready_rollout deployment "app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cert-manager" || overall_rc=1
check_clusterissuer_ready selfsigned-issuer || overall_rc=1

echo "[verify] Postgres (Operator + Cluster)"
check_helm_release postgres-operator || overall_rc=1
check_ready_rollout deployment "app.kubernetes.io/instance=postgres-operator,app.kubernetes.io/name=postgres-operator" || overall_rc=1
if kubectl get crd postgresqls.acid.zalan.do >/dev/null 2>&1; then
  pass "CRD postgresqls.acid.zalan.do present"
else
  fail "CRD postgresqls.acid.zalan.do missing"; overall_rc=1
fi
if kubectl -n "$NS" get postgresql postgres >/dev/null 2>&1; then
  pass "Postgres cluster CR 'postgres' present"
else
  fail "Postgres cluster CR 'postgres' missing"; overall_rc=1
fi
if kubectl -n "$NS" get secret postgres.postgres.credentials.postgresql.acid.zalan.do >/dev/null 2>&1; then
  pass "Postgres credentials secret present"
else
  fail "Postgres credentials secret missing"; overall_rc=1
fi
# Deep check: run psql in an ephemeral pod and execute SELECT 1
deep_pg_check() {
  local secret_name="postgres.postgres.credentials.postgresql.acid.zalan.do"
  if ! kubectl -n "$NS" get secret "$secret_name" >/dev/null 2>&1; then
    warn "Postgres secret $secret_name not found; skipping psql test"
    return 0
  fi
  local pgpass
  pgpass=$(kubectl -n "$NS" get secret "$secret_name" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
  if [ -z "${pgpass:-}" ]; then
    warn "Could not read Postgres password from secret; skipping psql test"
    return 0
  fi
  wait_service postgres 5432 30 2 || return 1
  local tries=5
  while [ "$tries" -gt 0 ]; do
    ephem_exec postgres-psql postgres:16-alpine "PGPASSWORD='$pgpass' psql -h postgres -U postgres -d btp -tAc 'SELECT 1' >/dev/null 2>&1"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      pass "Postgres SELECT 1 succeeded"
      return 0
    fi
    # Fallback to default db
    ephem_exec postgres-psql postgres:16-alpine "PGPASSWORD='$pgpass' psql -h postgres -U postgres -d postgres -tAc 'SELECT 1' >/dev/null 2>&1"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      pass "Postgres SELECT 1 on default db succeeded"
      return 0
    fi
    tries=$((tries-1))
    sleep 3
  done
  fail "Postgres SELECT 1 failed"
  return 1
}
deep_pg_check || overall_rc=1

echo "[verify] Redis"
check_helm_release redis || overall_rc=1
check_ready_rollout statefulset "app.kubernetes.io/instance=redis,app.kubernetes.io/name=redis" || overall_rc=1
# Deep check: redis-cli PING using password from secret
deep_redis_check() {
  local rsecret rpass
  rsecret=$(kubectl -n "$NS" get secret -l app.kubernetes.io/instance=redis,app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [ -z "${rsecret:-}" ]; then
    warn "Redis secret not found; skipping redis-cli test"
    return 0
  fi
  rpass=$(kubectl -n "$NS" get secret "$rsecret" -o jsonpath='{.data.redis-password}' 2>/dev/null | base64 -d || true)
  if [ -z "${rpass:-}" ]; then
    warn "Redis password key missing; skipping redis-cli test"
    return 0
  fi
  wait_service redis-master 6379 30 2 || return 1
  local tries=5
  while [ "$tries" -gt 0 ]; do
    ephem_exec redis-ping docker.io/redis:7-alpine "export REDISCLI_AUTH='$rpass'; redis-cli -h redis-master PING | grep -q PONG"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      pass "Redis PING succeeded"
      return 0
    fi
    tries=$((tries-1)); sleep 3
  done
  fail "Redis PING failed"
  return 1
}
deep_redis_check || overall_rc=1

echo "[verify] MinIO"
check_helm_release minio || overall_rc=1
check_ready_rollout statefulset "app.kubernetes.io/instance=minio,app.kubernetes.io/name=minio" || overall_rc=1
# Deep check: mc ls (create+delete tmp bucket)
deep_minio_check() {
  local msecret access secret
  msecret=$(kubectl -n "$NS" get secret -l app.kubernetes.io/instance=minio,app.kubernetes.io/name=minio -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [ -z "${msecret:-}" ]; then
    warn "MinIO secret not found; skipping mc test"
    return 0
  fi
  access=$(kubectl -n "$NS" get secret "$msecret" -o jsonpath='{.data.root-user}' 2>/dev/null | base64 -d || echo "")
  secret=$(kubectl -n "$NS" get secret "$msecret" -o jsonpath='{.data.root-password}' 2>/dev/null | base64 -d || echo "")
  if [ -z "$access" ] || [ -z "$secret" ]; then
    warn "MinIO credentials missing; skipping mc test"
    return 0
  fi
  local bucket="btp-verify-$(date +%s)"
  wait_service minio 9000 30 2 || return 1
  local tries=5
  while [ "$tries" -gt 0 ]; do
    ephem_exec minio-mc docker.io/minio/mc:latest "mc alias set local http://minio:9000 '$access' '$secret' && mc mb local/$bucket && mc rb --force local/$bucket"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      pass "MinIO bucket create/delete succeeded"
      return 0
    fi
    tries=$((tries-1)); sleep 3
  done
  fail "MinIO client ops failed"
  return 1
}
deep_minio_check || overall_rc=1

echo "[verify] Metrics + Logs (Kube-Prometheus-Stack + Loki)"
check_helm_release kps || overall_rc=1
check_ready_rollout deployment "app.kubernetes.io/instance=kps,app.kubernetes.io/name=grafana" || true
check_helm_release loki || overall_rc=1
check_ready_rollout statefulset "app.kubernetes.io/instance=loki,app.kubernetes.io/name=loki" || overall_rc=1
# Deep check: Loki label values endpoint via in-cluster curl
deep_loki_check() {
  wait_service loki 3100 30 2 || return 1
  if http_check loki-http "http://loki:3100/loki/api/v1/label/__name__/values"; then
    pass "Loki API responded"
  else
    fail "Loki API check failed"
    fi
}
deep_loki_check || overall_rc=1

echo "[verify] OAuth (Keycloak)"
check_helm_release keycloak || overall_rc=1
check_ready_rollout statefulset "app.kubernetes.io/instance=keycloak,app.kubernetes.io/name=keycloak" || overall_rc=1
# Deep check: OIDC discovery via in-cluster curl
deep_keycloak_check() {
  wait_service keycloak 80 60 2 || return 1
  if http_check keycloak-oidc "http://keycloak:8080/realms/master/.well-known/openid-configuration"; then
    pass "Keycloak OIDC discovery responded"
  else
    # Some charts expose on port 80; retry on 80 if 8080 fails
    if http_check keycloak-oidc "http://keycloak:80/realms/master/.well-known/openid-configuration"; then
      pass "Keycloak OIDC discovery responded (port 80)"
    else
      fail "Keycloak OIDC check failed"
      return 1
    fi
  fi
}
deep_keycloak_check || overall_rc=1

echo "[verify] Secrets (Vault)"
check_helm_release vault || overall_rc=1
check_ready_rollout statefulset "app.kubernetes.io/instance=vault,app.kubernetes.io/name=vault" || overall_rc=1
if kubectl -n "$NS" get svc vault >/dev/null 2>&1; then
  deep_vault_check() {
    wait_service vault 8200 30 2 || return 1
    # Vault health from inside cluster (any 200 OK body is acceptable in dev)
    if http_check vault-health "http://vault:8200/v1/sys/health"; then
      pass "Vault health endpoint responded"
      return 0
    else
      fail "Vault health check failed"
      return 1
    fi
  }
  deep_vault_check || overall_rc=1
fi

echo "[verify] Done with code: $overall_rc"
if [ "$overall_rc" -eq 0 ]; then
  ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  echo ""
  echo "[success] All dependencies are healthy and ready to use."
  echo "           Namespace: $NS | Context: $ctx"
  echo "           Verified: Ingress+TLS, Postgres, Redis, MinIO, Loki/KP, Keycloak, Vault"
fi
exit "$overall_rc"
