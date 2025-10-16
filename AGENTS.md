# Repository Guidelines

## Terraform Architecture Principles
- Treat the root module (`/`) as orchestration only: parse tfvars, call modules, surface outputs. No provider-specific logic, merges, or shell hooks in root locals.
- Each dependency lives in `/deps/<name>/` with a consistent layout:
  - `main.tf` dispatches on `mode` and forwards `config` blocks to provider implementations.
  - `modes/<provider>.tf` owns all provider-specific resources, helper locals, and defaults.
  - `variables.tf` defines a unified contract (one `mode`, optional `config` objects per provider, strong defaults).
  - `outputs.tf` exposes normalized outputs consumed by other modules.
- Cloud scaffolding belongs under `/cloud/{aws,azure,gcp,generic}/`, returning shared infrastructure (networking, IAM, kubeconfig helpers) for dependencies to consume.
- The BTP Helm release (`/btp`) receives normalized dependency outputs; it creates any namespaces it needs directly before installing the chart.
- Dependencies must not reach across provider boundaries. Compose cross-provider stacks by instantiating multiple dependency modules from the root.

## Project Structure & Module Organization
- Root Terraform module: `/` wires cloud/platform helpers, dependency modules, and the BTP release.
- Cloud scaffolding: `/cloud/{aws,azure,gcp,generic}` (future managed/BYO patterns).
- Dependencies: `/deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}` following the architecture principles above.
- BTP Helm release: `/btp` (maps dependency outputs to chart values, handles target namespaces).
- Examples: `/examples/*.tfvars` (e.g., `generic-orbstack-dev.tfvars`).
- Utilities: `/scripts/` (helper utilities, if present), docs in `/docs/`.

## Coding Style & Naming Conventions
- HCL2 with 2‑space indentation; wrap at ~100 cols.
- Variables/outputs use `snake_case`; modules and resources use explicit names (prefer `btp_*` where helpful).
- Inputs surface the minimal knobs with sensible defaults; provider-specific defaults live in provider mode files.
- Keep modules small with a single purpose; expose a stable, documented output contract.
- Always run `terraform fmt` before committing.

## Build, Test, and Development Commands
- Initialize providers/modules: `terraform init` (repo root).
- Lint/format: `terraform fmt -recursive` and `terraform validate`.
- Plan against an environment: `terraform plan -var-file examples/generic-orbstack-dev.tfvars`.
- Apply/destroy: `terraform apply -var-file …` / `terraform destroy -var-file …`.
- Local readiness: run `terraform init`, confirm `kubectl`/`helm` connectivity, and add required Helm repositories as documented.

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
- Preserve the three-mode pattern per dependency (`managed | k8s | byo`) even if only one mode is implemented today.
- Maintain unified outputs consumed by `/btp`; avoid breaking contracts.
- Add examples and docs alongside any module or variable changes (docs updates can follow in a later stage but must be tracked).

## Documentation & Mermaid Guidelines
- Docs live under `docs/` as Markdown files only (no site generators). Keep pages small and focused; link richly.
- Follow the docs IA in `docs/PLAN.md`. New pages must fit the structure; avoid ad-hoc top-level files.
- Auto-generate Terraform references per module with `terraform-docs` into `docs/reference/terraform/`. Do not hand-edit generated tables.
- Example configurations belong in `examples/*.tfvars` and must have a matching short explainer page under `docs/examples/`.
- Keep the three-mode pattern (managed | k8s | byo) consistently described for every dependency and provider.

### Mermaid Rules
- Use Mermaid extensively, but avoid clutter: prefer several focused diagrams over one busy diagram; include a single large “whole picture” where appropriate.
- Always include an init block enabling HTML labels so we can embed icons:
  ```mermaid
  %%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
  ```
- Store icons at `docs/assets/icons/{aws,azure,gcp,k8s,btp}/*.svg` and reference them via HTML labels, e.g.: `<img src='assets/icons/aws/s3.svg' width='18'/>`.
- Use provider subgraphs and consistent classDefs for borders/colors: AWS `#FF9900`, Azure `#0078D4`, GCP `#EA4335`, K8s `#326CE5`.
- Keep node labels short: `Icon + Short name (capability)`. Limit to ~12 nodes per diagram unless explicitly documenting the full architecture.
- Validate diagrams render cleanly (no overlapping edges; minimal cross-graph links). Prefer left-to-right (LR) for architecture overviews.

### Docs PR Checklist
- Run `terraform fmt -recursive` and `terraform validate`.
- Update or regenerate module references with `terraform-docs` if variables/outputs changed.
- Add/update example `*.tfvars` and their explainer pages if behavior or inputs changed.
- Update relevant diagrams and the compatibility matrix when adding/changing providers, modes, or resources.
- Ensure sensitive values are not shown in docs; mark outputs `sensitive` in code where applicable.
