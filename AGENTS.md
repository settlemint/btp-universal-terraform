# Repository Guidelines

## Project Structure & Module Organization
- Root Terraform module: `/` wires cloud/platform and dependency modules.
- Cloud scaffolding: `/cloud/{aws,azure,gcp,generic}` (future managed/BYO).
- Dependencies: `/deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}` (unified outputs).
- BTP Helm release: `/btp` (maps dependency outputs to chart values).
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
- Maintain unified outputs consumed by `/btp`; avoid breaking contracts.
- Add examples and docs alongside any module or variable changes.

## Documentation & Mermaid Guidelines
- Docs live under `docs/` as Markdown files only (no site generators). Keep pages small and focused; link richly.
- Follow the docs IA in `docs/PLAN.md`. New pages must fit the structure; avoid ad‑hoc top-level files.
- Auto-generate Terraform references per module with `terraform-docs` into `docs/reference/terraform/`. Do not hand‑edit generated tables.
- Example configurations belong in `examples/*.tfvars` and must have a matching short explainer page under `docs/examples/`.
- Keep the three‑mode pattern (managed | k8s | byo) consistently described for every dependency and provider.

### Mermaid Rules
- Use Mermaid extensively, but avoid clutter: prefer several focused diagrams over one busy diagram; include a single large “whole picture” where appropriate.
- Always include an init block enabling HTML labels so we can embed icons:
  ```mermaid
  %%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
  ```
- Store icons at `docs/assets/icons/{aws,azure,gcp,k8s,btp}/*.svg` and reference them via HTML labels, e.g.: `<img src='assets/icons/aws/s3.svg' width='18'/>`.
- Use provider subgraphs and consistent classDefs for borders/colors: AWS `#FF9900`, Azure `#0078D4`, GCP `#EA4335`, K8s `#326CE5`.
- Keep node labels short: `Icon + Short name (capability)`. Limit to ~12 nodes per diagram unless explicitly documenting the full architecture.
- Validate diagrams render cleanly (no overlapping edges; minimal cross‑graph links). Prefer left‑to‑right (LR) for architecture overviews.

### Docs PR Checklist
- Run `terraform fmt -recursive` and `terraform validate`.
- Update or regenerate module references with `terraform-docs` if variables/outputs changed.
- Add/update example `*.tfvars` and their explainer pages if behavior or inputs changed.
- Update relevant diagrams and the compatibility matrix when adding/changing providers, modes, or resources.
- Ensure sensitive values are not shown in docs; mark outputs `sensitive` in code where applicable.
