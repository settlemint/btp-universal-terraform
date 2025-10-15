# Dependency — Object Storage

Summary
- Durable storage for artifacts, backups, and logs via S3-compatible outputs.

Modes at a glance
- managed: S3 (AWS) | Blob (Azure) | GCS (GCP)
- k8s: MinIO (dev-friendly)
- byo: External bucket/endpoint

How k8s mode works (this repo)
- Installs Bitnami MinIO, no persistence for dev; creates a default bucket
- Inputs: `default_bucket`, `access_key`, `secret_key`, `chart_version`, `release_name`, `values`
- Outputs: `endpoint`, `bucket`, `access_key`, `secret_key`, `region=us-east-1`, `use_path_style=true`

Managed mode (guidance)
- AWS S3: enforce encryption, versioning, lifecycle; IAM policies
- Terraform force-deletes managed buckets by default (`aws.force_destroy = true`) so destroys succeed even with leftover objects; set to `false` if you need protection against accidental wipes.
- Reuse an existing bucket by setting `aws.manage_bucket = false`; Terraform will reference it instead of creating a new one.
- Default bucket names follow `btp-<hash>-artifacts`, derived from `base_domain` to stay globally unique.
- Azure Blob: storage account + container, SAS/keys; consider native SDKs
- GCP GCS: bucket with uniform access; HMAC keys for S3 clients

BYO mode
- Inputs: `endpoint`, `bucket`, `region`, `access_key`, `secret_key`, `use_path_style`

Examples
```hcl
object_storage = { mode = "k8s", k8s = { default_bucket = "btp-artifacts" } }

object_storage = {
  mode = "managed"
  managed = { provider = "aws", bucket = "btp-artifacts", region = "eu-west-1" }
}

object_storage = {
  mode = "aws"
  aws = {
    manage_bucket = false # Skip creation and bind to an existing bucket
    bucket_name   = "existing-btp-artifacts"
  }
}
```

Diagram
```mermaid
flowchart LR
  App-->OBJ[(Object Storage)]
```

Verification (k8s mode)
```bash
ACCESS_KEY=$(terraform output -json object_storage | jq -r .access_key)
SECRET_KEY=$(terraform output -json object_storage | jq -r .secret_key)
ENDPOINT=$(terraform output -json object_storage | jq -r .endpoint)
mc alias set local $ENDPOINT $ACCESS_KEY $SECRET_KEY --api S3v4
mc ls local
```

Security & gotchas
- Enforce versioning, encryption, lifecycle on managed buckets; avoid plaintext creds in repos
- Path-style vs virtual-hosted addressing differs by provider/gateway; use `use_path_style` when needed
- AWS bucket overrides must be globally unique and lowercase; omit `bucket_name` to let the module derive a hashed name safely.

Next steps
- See how `/btp` consumes these outputs in docs/modules/btp.md
