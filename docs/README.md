# Documentation Index

Use this folder to navigate the SettleMint BTP Universal Terraform documentation. Begin with the core articles, then drill into provider specifics or dependency details as needed.

- **Overview** – `docs/overview.md` explains what the stack delivers and how the dependency contract works.
- **Architecture** – `docs/architecture.md` shows how cloud scaffolding, dependencies, and the Helm release connect.
- **Concepts** – `docs/concepts.md` documents the dependency modes and normalized outputs.
- **Getting Started** – `docs/getting-started.md` walks through prerequisites, workflows, and example tfvars.
- **Configuration** – `docs/configuration.md` (new) highlights the root variables you actually need to set.
- **Providers** – `docs/providers/*.md` covers provider expectations; only AWS ships managed mode today.
- **Dependencies** – `docs/dependencies.md` maps which modes exist per dependency and their outputs.
- **Operations** – `docs/operations.md` records day-2 tasks like exporting kubeconfig and rotating secrets.
- **Troubleshooting** – `docs/troubleshooting.md` lists the issues we have actually seen and how to fix them.
- **Security** – `docs/security.md` summarizes the controls implemented in Terraform today so expectations stay grounded.

Keep new content short, reference the Terraform modules directly, and update `examples/*.tfvars` and docs together whenever inputs or outputs change.
