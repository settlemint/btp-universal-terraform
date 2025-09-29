# State and Environments

- Use a remote backend for shared envs (e.g., S3+DynamoDB, Azure Storage, GCS).
- Keep separate workspaces or separate state files per environment.
- Store environment profiles as `examples/*.tfvars` and reference them in plans.
- Never commit secrets to tfvars; prefer secret backends or environment variables.

