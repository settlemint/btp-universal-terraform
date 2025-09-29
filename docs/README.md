# BTP Universal Terraform — Docs Hub

Welcome! This is your guided tour of the stack: what it deploys, how it’s wired, and how to run it anywhere. The docs are concise, visual, and practical — heavy on diagrams, light on fluff.

TL;DR (pick one)
- 🚀 Local first run: docs/quickstart/local.md
- ☁️ Cloud profile: docs/quickstart/cloud.md
- 🧠 Understand modes + outputs: docs/concepts/modes.md, docs/concepts/outputs-contract.md
- 🗺️ See the big picture: docs/architecture/whole-picture.md

Choose your setup (architectures)
- AWS (all managed): docs/architecture/aws-full.md
- Azure (all managed): docs/architecture/azure-full.md
- GCP (all managed): docs/architecture/gcp-full.md
- Kubernetes only (all k8s): docs/architecture/k8s-full.md

What you get
- Ingress + TLS, Postgres, Redis, Object Storage, OAuth, Secrets, Metrics/Logs, and the BTP Helm release
- Modes per dependency: managed | k8s | byo (mix-and-match across AWS, Azure, GCP)

Choose your path
- Just try it locally in minutes → docs/quickstart/local.md
- Apply a managed/cloud mix for real environments → docs/quickstart/cloud.md
- Dive into each capability → docs/modules/deps/postgres.md (and friends)
- Wire-up of Helm values → docs/modules/btp.md

How these docs are organized
- Quickstarts: shortest path to working
- Concepts: why managed | k8s | byo and how outputs unify everything
- Architecture: visual guide to how pieces fit
- Modules: deep dives per dependency and cloud
- Reference: IAM, compatibility, terraform-docs
- Operations: runbooks, troubleshooting
- Security & Cost: posture and spend

Repo map
- Root module orchestrates `deps/*` and optionally installs `/btp`
- `deps/*` implement capabilities and emit unified outputs
- `btp/` consumes outputs and installs the Platform Helm chart
- `examples/*.tfvars` are ready-to-run environment profiles
- `scripts/` provides preflight, install, lint/verify, docs helpers

Conventions
- Markdown-only; Mermaid diagrams with icons and clean layout
- Short paragraphs, action-first; secrets always redacted
