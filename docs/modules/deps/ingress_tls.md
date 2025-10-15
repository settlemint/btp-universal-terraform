# Dependency — Ingress & TLS

Summary
- HTTP ingress and TLS termination with a consistent class and issuer model.

Modes at a glance
- managed: ALB+ACM (AWS) | App Gateway+Key Vault (Azure) | HTTPS LB+Managed Certs (GCP)
- k8s: NGINX Ingress + cert-manager (ClusterIssuer)
- byo: External ingress endpoints and certs

How k8s mode works (this repo)
- Installs ingress-nginx and cert-manager (CRDs), creates a self-signed ClusterIssuer
- Switches to Route53 DNS-01 validation when a zone ID is passed from `/deps/dns`; if AWS credentials are provided it seeds a `route53-credentials` Secret automatically.
- Inputs: `nginx_chart_version`, `cert_manager_chart_version`, `issuer_name`, `values_*`, `acme_email`, `route53_credentials_secret_name`
- If `acme_email` is unset or uses a placeholder (e.g., `example.com`), Terraform falls back to the license email so the Let's Encrypt account registers successfully.
- Provisions a wildcard certificate in the ingress-nginx namespace and sets it as the controller's default, so dynamically-created services (e.g., deployment engine nodes) immediately serve trusted HTTPS even without custom TLS blocks.
- Outputs: `ingress_class="nginx"`, `issuer_name`

Managed mode (guidance)
- AWS: ALB Ingress Controller, ACM, Route53; annotate services appropriately
- Azure: AGIC with Key Vault certs via managed identity
- GCP: Cloud HTTP(S) LB with managed certs and BackendConfig

BYO mode
- Inputs: `ingress_class`, `issuer_name` or `tls_secret_name`, hosts

Diagram
```mermaid
flowchart LR
  U[User] -->|HTTPS| Ingress
  Ingress --> svc[Service]
  Ingress -. cert-manager .-> CA[(ACME/Provider CA)]
```

Verification (k8s mode)
```bash
kubectl get pods -n <namespace> | egrep "ingress|cert"
kubectl get clusterissuer
```

Security & gotchas
- Use real ACME/provider-managed certs outside local; private LBs and WAFs recommended
- Webhook timing for cert-manager CRDs — this module waits, but slow clusters may need extra time
- Override `acme_email` so Let's Encrypt notifications reach the right team; defaults fall back to the license email before using the internal SettleMint address.

Next steps
- Configure application hosts in `/btp` values referencing the chosen issuer
