# Runbook — Rotate TLS Certificates

Summary: Replace TLS certs with zero/minimal downtime.

Steps
1) Issue new cert (managed or cert-manager)
2) Update secret or cert reference
3) `terraform apply`
4) Verify ingress and certificate chain

