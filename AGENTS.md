# Repository Guidelines

## Project Structure & Module Organization
- Root Terraform module: `/` wires cloud/platform and dependency modules.
- Cloud scaffolding: `/cloud/{aws,azure,gcp,generic}` (future managed/BYO).
- Dependencies: `/deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}` (unified outputs).
- BTP Helm release: `/btp_helm` (maps dependency outputs to chart values).
- Examples: `/examples/*.tfvars` (e.g., `generic-orbstack-dev.tfvars`).
- Utilities: `/scripts/` (e.g., `preflight.sh`), docs in `/docs/`.

## Build, Test, and Development Commands
- Initialize providers/modules: `terraform init` (run in repo root).
- Lint/format: `terraform fmt -recursive` and `terraform validate`.
- Plan against an environment: `terraform plan -var-file examples/generic-orbstack-dev.tfvars`.
- Apply/destroy: `terraform apply -var-file …` / `terraform destroy -var-file …`.
- Local readiness: `./scripts/preflight.sh` (adds Helm repos, checks kubectl/helm, storage class).

## Coding Style & Naming Conventions
- HCL2 with 2‑space indentation; wrap at ~100 cols.
- Variables/outputs use `snake_case`; modules and resources use clear, explicit names (prefer `btp_*` prefixes where helpful).
- Keep modules small with a single purpose; expose a stable, documented output contract.
- Always run `terraform fmt` before committing.

## Testing Guidelines
- Static checks: `terraform validate`, optional `tflint`/`checkov` if configured.
- Dry-run plans for both dev and prod examples; attach plan snippets to PRs when relevant.
- For OrbStack, verify ingress reachability on `*.127.0.0.1.nip.io` after apply.

## Commit & Pull Request Guidelines
- Write clear, scoped commits; Conventional Commits style is preferred (e.g., `feat: add redis k8s mode`).
- PRs must include: purpose/changes, linked issue, commands used (`init/plan/apply`), and notes on outputs or breaking changes.
- Update `/docs` and example `*.tfvars` when changing inputs/outputs.

## Security & Configuration Tips
- Do not commit secrets or tfvars with credentials. Mark sensitive outputs and avoid echoing them in logs.
- Use remote state backends for shared environments; pin provider versions.
- Default to TLS and least privilege; prefer secret backends (Vault/cloud) over plaintext.

## Agent-Specific Notes
- Preserve the three-mode pattern per dependency (`managed | k8s | byo`) even if only `k8s` is implemented now.
- Maintain unified outputs consumed by `/btp_helm`; avoid breaking contracts.
- Add examples and docs alongside any module or variable changes.
