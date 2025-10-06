# Code Review - Multi-Cloud Terraform Refactor

## 🚨 Critical Issues

### 1. Unused AWS Account ID Data Source
**Location:** `providers.tf:34`
```hcl
data "aws_caller_identity" "current" {}
```
- Declared but never referenced
- **Action:** Remove or use it

### 2. ClusterIssuer Using null_resource (Intentional Design) ✅
**Location:** `deps/ingress_tls/main.tf:50-84`
- Uses `null_resource` + kubectl instead of `kubernetes_manifest`
- **This is intentional and necessary** due to terraform provider limitations:
  - `kubernetes_manifest` requires K8s API connection during plan phase
  - Cluster doesn't exist during initial plan → causes "no client config" error
  - `null_resource` defers execution to apply phase when cluster is ready
- Destroy provisioner includes `--ignore-not-found=true` for safety
- **Status:** Accepted as valid pattern for this use case

### 3. Conditional Resource in depends_on
**Location:** `main.tf:48-52`
```hcl
depends_on = [
  module.k8s_cluster,
  local_file.kubeconfig  # This has count=1, won't exist in BYO mode
]
```
- Will cause errors in BYO mode
- **Action:** Remove `local_file.kubeconfig` from depends_on

## ⚠️ Major Issues

### 4. RDS Password Character Set Issues
**Location:** `deps/postgres/aws.tf:4-9`
- `override_special = "!#$%&*()-_=+[]{}<>:?"` includes shell-dangerous chars like `<>`
- Missing safe chars like `~` or `^`
- **Action:** Review and fix character set

### 5. Deprecated Kubernetes API Version
**Location:** `providers.tf:56-58, 82-84`
```hcl
api_version = "client.authentication.k8s.io/v1beta1"
```
- Should use `v1` (stable since K8s 1.24+)
- **Action:** Change to `v1`

### 6. Complex Kubeconfig Path Logic
**Location:** `providers.tf:24-33`
- 4-level nested ternary is hard to read/debug
- **Action:** Extract to clearer local variables

### 7. Duplicate AWS Exec Block
**Location:** `providers.tf:47-73`
- Same AWS exec logic duplicated in kubernetes and helm providers
- DRY violation
- **Action:** Extract to local variable

## 🔍 Medium Issues

### 8. Provider Version Constraints Too Loose
**Location:** `versions.tf`
- `aws = "~> 5.0"` allows 5.0-5.99
- `azurerm = "~> 4.0"` allows 4.0-4.99
- `google = "~> 6.0"` allows 6.0-6.99
- **Action:** Consider tighter constraints like `>= 5.0, < 6.0`

### 9. Missing Output Description
**Location:** `outputs.tf:83-99`
- New `k8s_cluster` output has no description
- Inconsistent with other outputs
- **Action:** Add description

### 10. Cert-Manager Sleep Duration Reduced
**Location:** `deps/ingress_tls/main.tf:43-46`
- Changed from 90s to 60s
- Might cause race conditions on slower clusters
- **Action:** Monitor for issues

### 11. Trailing Whitespace
**Location:** `providers.tf:94`
- Extra blank line at EOF
- **Action:** Remove for consistency

## ✅ Good Things

- Multi-cloud support well structured
- Mode-based configuration is clean
- Proper use of `depends_on` in most places
- Good separation of provider-specific configs
- Lock file properly updated

## 🎯 Priority Recommendations

### Must Fix (P1)
1. ✅ Remove unused `data.aws_caller_identity.current`
2. ✅ Fix `depends_on = [local_file.kubeconfig]` - conditional resource issue
3. ✅ Change API version from `v1beta1` to `v1`
4. ✅ Keep `null_resource` in ingress_tls (intentional design for plan-phase issues)

### Should Fix (P2)
5. Extract duplicate AWS exec block to local
6. Simplify kubeconfig_path ternary logic
7. Add descriptions to new outputs
8. Review RDS password character set

### Nice to Have (P3)
9. Add VPC output validation when mode=aws
10. Consider splitting provider-specific outputs
11. Remove trailing whitespace
