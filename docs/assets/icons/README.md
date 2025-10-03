# Icons

Folders
- `docs/assets/icons/aws/*.svg`
- `docs/assets/icons/azure/*.svg`
- `docs/assets/icons/gcp/*.svg`
- `docs/assets/icons/k8s/*.svg`
- `docs/assets/icons/btp/*.svg`

Manifest
- See `docs/assets/icons/manifest.json` for the complete, expected list of icons.
- Use `scripts/stub-icons.sh` to generate placeholders for any missing icons.
- Use `scripts/verify-icons.sh` to list missing icons.

Usage in Mermaid
- Reference like: `<img src='assets/icons/aws/s3.svg' width='18'/>`

Sourcing real icons (manual, recommended)
- AWS Architecture Icons: architecture-icons (requires acceptance of AWS terms)
- Azure Product Icons: Microsoft Azure icon set (official docs site)
- GCP Icons: Google Cloud icons (brand guidelines apply)
- CNCF projects: cncf/artwork repo
- Simple Icons: for provider logos only (not service icons)

Licensing
- Respect vendor licensing/brand guidelines. Do not commit restricted assets without approval.
