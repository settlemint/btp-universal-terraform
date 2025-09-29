# Docs Style Guide

Tone & voice
- Crisp, active, friendly; show, don’t tell
- Lead with the outcome; keep paragraphs short (2–3 lines)
- Use emojis sparingly to signal sections (e.g., 🚀 Quickstart, 🛡️ Security)

Structure (page template)
- Title
- Summary (2–3 bullets)
- At a glance (what, why, when)
- Diagram (Mermaid, focused)
- How it works (practical description)
- Inputs (bullets) and Outputs (bullets) — link to terraform-docs when available
- Step-by-step (numbered) with copy-paste commands
- Verification (commands)
- Security & gotchas (bullets)
- Examples / Profiles (optional)
- Next steps (links)

Mermaid
- Always include an init block and prefer LR for architecture; embed icons via HTML labels
- Keep ≤12 nodes; split into multiple diagrams if needed

Formatting
- Use headings liberally; keep 4–6 bullets per list
- Code blocks for commands; inline code for identifiers
- Tables only when they add clarity (e.g., mode/provider mapping)

Secrets
- Never print real secrets; redact with `…`; mark outputs sensitive in Terraform
