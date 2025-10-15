resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  cert_manager_ready_seconds = 60
  cert_manager_timeout       = 600
}

resource "helm_release" "ingress_nginx" {
  name            = var.release_name_nginx
  namespace       = var.namespace
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  version         = var.nginx_chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(local.ingress_nginx_values)
  ]
}

resource "helm_release" "cert_manager" {
  name            = var.release_name_cert_manager
  namespace       = var.namespace
  repository      = "https://charts.jetstack.io"
  chart           = "cert-manager"
  version         = var.cert_manager_chart_version
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = local.cert_manager_timeout

  values = [
    yamlencode(merge({
      installCRDs = true
    }, var.values_cert_manager))
  ]
}

# Wait for cert-manager CRDs to be installed
resource "time_sleep" "wait_for_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "${local.cert_manager_ready_seconds}s"
}

locals {
  use_dns01              = var.route53_zone_id != null
  route53_secret         = coalesce(var.route53_credentials_secret_name, "route53-credentials")
  route53_creds_provided = var.aws_access_key_id != null && var.aws_secret_access_key != null
  manage_route53_secret  = local.use_dns01 && local.route53_creds_provided
  acme_email_input       = var.acme_email != null ? trimspace(var.acme_email) : ""
  acme_email             = length(local.acme_email_input) > 0 ? local.acme_email_input : "devops@settlemint.com"
  acme_solver_dns = {
    dns01 = {
      route53 = {
        region       = var.aws_region
        hostedZoneID = var.route53_zone_id
        accessKeyIDSecretRef = {
          name = local.route53_secret
          key  = "access-key-id"
        }
        secretAccessKeySecretRef = {
          name = local.route53_secret
          key  = "secret-access-key"
        }
      }
    }
  }
  acme_solver_http = {
    http01 = {
      ingress = {
        class = "nginx"
      }
    }
  }
  acme_solvers = concat(
    local.use_dns01 ? [local.acme_solver_dns] : [],
    local.use_dns01 ? [] : [local.acme_solver_http]
  )
  clusterissuer_manifest = trimspace(yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.issuer_name
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = local.acme_email
        privateKeySecretRef = {
          name = "${var.issuer_name}-key"
        }
        solvers = local.acme_solvers
      }
    }
  }))

  default_certificate_input = var.default_certificate != null ? var.default_certificate : null
  default_certificate_enabled = local.default_certificate_input != null ? coalesce(
    try(local.default_certificate_input.enabled, null),
    true
  ) : false
  default_certificate_hosts = local.default_certificate_enabled ? distinct([
    for host in try(local.default_certificate_input.hosts, []) : trimspace(host)
    if trimspace(host) != ""
  ]) : []
  default_certificate_secret = local.default_certificate_enabled ? coalesce(
    try(local.default_certificate_input.secret_name, null),
    "ingress-wildcard-tls"
  ) : null
  default_certificate_manifest = local.default_certificate_enabled && length(local.default_certificate_hosts) > 0 ? trimspace(yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.default_certificate_secret
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"    = "ingress-wildcard-certificate"
        "app.kubernetes.io/managed" = "terraform"
      }
    }
    spec = {
      secretName = local.default_certificate_secret
      dnsNames   = local.default_certificate_hosts
      issuerRef = {
        name  = var.issuer_name
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  })) : ""

  ingress_controller_base = {
    ingressClassResource = { name = "nginx", default = true }
    service              = { type = "NodePort" }
    config = {
      "allow-snippet-annotations" = "true"
      "ssl-redirect"              = "false" # Disable global SSL redirect to allow HTTP-01 ACME challenges
    }
  }

  ingress_controller_tls = local.default_certificate_enabled && length(local.default_certificate_hosts) > 0 ? {
    extraArgs = {
      "default-ssl-certificate" = "${var.namespace}/${local.default_certificate_secret}"
    }
  } : {}

  ingress_controller_values = merge(
    local.ingress_controller_base,
    local.ingress_controller_tls
  )

  ingress_controller_user_overrides = try(var.values_nginx.controller, {})

  ingress_controller_config = merge(
    try(local.ingress_controller_base.config, {}),
    try(local.ingress_controller_tls.config, {}),
    try(local.ingress_controller_user_overrides.config, {})
  )

  ingress_controller_service = merge(
    try(local.ingress_controller_base.service, {}),
    try(local.ingress_controller_tls.service, {}),
    try(local.ingress_controller_user_overrides.service, {})
  )

  ingress_controller_extra_args = merge(
    try(local.ingress_controller_tls.extraArgs, {}),
    try(local.ingress_controller_base.extraArgs, {}),
    try(local.ingress_controller_user_overrides.extraArgs, {})
  )

  ingress_controller_final = merge(
    local.ingress_controller_values,
    {
      config    = local.ingress_controller_config
      service   = local.ingress_controller_service
      extraArgs = local.ingress_controller_extra_args
    },
    local.ingress_controller_user_overrides
  )

  ingress_nginx_values = merge(
    var.values_nginx,
    {
      controller = local.ingress_controller_final
    }
  )
}

resource "kubernetes_secret" "route53_credentials" {
  count = local.manage_route53_secret ? 1 : 0

  metadata {
    name      = local.route53_secret
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"     = "route53-credentials"
      "app.kubernetes.io/managed"  = "terraform"
      "app.kubernetes.io/instance" = var.release_name_cert_manager
    }
  }

  type = "Opaque"

  data = {
    "access-key-id"     = var.aws_access_key_id
    "secret-access-key" = var.aws_secret_access_key
  }
}

# Create ClusterIssuer using kubectl via null_resource
# NOTE: We use null_resource instead of kubernetes_manifest because:
# 1. kubernetes_manifest requires K8s API connection during plan phase
# 2. The cluster doesn't exist yet during initial plan
# 3. This would cause "cannot create REST client: no client config" errors
# The null_resource approach runs during apply phase when cluster is ready
resource "null_resource" "selfsigned_issuer" {
  depends_on = [time_sleep.wait_for_cert_manager]

  triggers = {
    issuer_name     = var.issuer_name
    kubeconfig_path = var.kubeconfig_path
    manifest        = local.clusterissuer_manifest
    route53_secret  = local.manage_route53_secret ? join(",", kubernetes_secret.route53_credentials[*].metadata[0].name) : ""
    acme_email      = local.acme_email
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl apply -f - <<'YAML'
${self.triggers.manifest}
YAML
    EOT
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl delete clusterissuer ${self.triggers.issuer_name} --ignore-not-found=true 2>/dev/null || true
    EOT
  }
}

resource "null_resource" "default_wildcard_certificate" {
  count = local.default_certificate_enabled && length(local.default_certificate_hosts) > 0 ? 1 : 0

  depends_on = [
    null_resource.selfsigned_issuer
  ]

  triggers = {
    kubeconfig_path = var.kubeconfig_path
    manifest        = local.default_certificate_manifest
    secret_name     = local.default_certificate_secret
    namespace       = var.namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl apply -f - <<'YAML'
${self.triggers.manifest}
YAML
    EOT
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl delete certificate ${self.triggers.secret_name} --namespace ${self.triggers.namespace} --ignore-not-found=true 2>/dev/null || true
    EOT
  }
}
