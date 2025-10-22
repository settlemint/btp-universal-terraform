resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  ingress_release_name = coalesce(var.release_name_nginx, "ingress")
  ingress_service_name = coalesce(
    var.load_balancer_service_name,
    try(var.values_nginx.controller.service.name, null),
    "${local.ingress_release_name}-ingress-nginx-controller"
  )
  ingress_service_tag = format("%s/%s", var.namespace, local.ingress_service_name)
  ingress_lb_tags = var.lookup_load_balancer ? merge(
    { "kubernetes.io/service-name" = local.ingress_service_tag },
    var.cluster_name != null ? { "elbv2.k8s.aws/cluster" = var.cluster_name } : {},
    var.load_balancer_tags
  ) : {}
}

data "kubernetes_service" "ingress" {
  count = var.lookup_load_balancer ? 1 : 0

  metadata {
    name      = local.ingress_service_name
    namespace = var.namespace
  }

  depends_on = [helm_release.ingress_nginx]
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
  route53_secret          = coalesce(var.route53_credentials_secret_name, "route53-credentials")
  route53_creds_provided  = var.aws_access_key_id != null && var.aws_secret_access_key != null
  use_dns01               = local.route53_creds_provided && try(var.route53_zone_id, null) != null
  manage_route53_secret   = local.route53_creds_provided
  acme_email_explicit_raw = var.acme_email != null ? trimspace(var.acme_email) : ""
  acme_email_explicit_valid = (
    length(local.acme_email_explicit_raw) > 0 &&
    !can(regex("example\\.com$", lower(local.acme_email_explicit_raw)))
  )
  acme_email_candidates_normalized = [
    for candidate in var.acme_email_candidates : trimspace(candidate)
    if trimspace(candidate) != "" && !can(regex("example\\.com$", lower(trimspace(candidate))))
  ]
  acme_email = local.acme_email_explicit_valid ? local.acme_email_explicit_raw : (
    length(local.acme_email_candidates_normalized) > 0 ? local.acme_email_candidates_normalized[0] : "devops@example.com"
  )
  acme_environment = lower(var.acme_environment)
  acme_server      = local.acme_environment == "staging" ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
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
        server = local.acme_server
        email  = local.acme_email
        privateKeySecretRef = {
          name = "${var.issuer_name}-key"
        }
        solvers = local.acme_solvers
      }
    }
  }))

  wildcard_host_candidates = compact([
    try(var.dns_context.wildcard_hostname, null)
  ])
  primary_hostname = try(var.dns_context.hostname, null)
  derived_default_certificate = var.default_certificate != null ? var.default_certificate : (
    length(local.wildcard_host_candidates) > 0 ? {
      enabled = true
      secret_name = format(
        "%s-wildcard",
        replace(coalesce(var.base_domain, local.primary_hostname, "btp.local"), ".", "-")
      )
      hosts = distinct(concat(
        local.wildcard_host_candidates,
        local.primary_hostname != null ? [local.primary_hostname] : []
      ))
    } : null
  )
  default_certificate_input = local.derived_default_certificate
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
    acme_server     = local.acme_server
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

data "aws_lbs" "ingress" {
  count = var.lookup_load_balancer && length(local.ingress_lb_tags) > 0 ? 1 : 0
  tags  = local.ingress_lb_tags
}

data "aws_lb" "ingress" {
  count = var.lookup_load_balancer && length(local.ingress_lb_tags) > 0 && length(try(tolist(data.aws_lbs.ingress[0].arns), [])) > 0 ? 1 : 0
  arn   = tolist(data.aws_lbs.ingress[0].arns)[0]
}

locals {
  ingress_lb_hostname = var.lookup_load_balancer ? try(data.kubernetes_service.ingress[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
  ingress_lb_ip       = var.lookup_load_balancer ? try(data.kubernetes_service.ingress[0].status[0].load_balancer[0].ingress[0].ip, null) : null
  ingress_lb_dns_name = length(data.aws_lb.ingress) > 0 ? data.aws_lb.ingress[0].dns_name : local.ingress_lb_hostname
  ingress_lb_zone_id  = length(data.aws_lb.ingress) > 0 ? data.aws_lb.ingress[0].zone_id : null
}
