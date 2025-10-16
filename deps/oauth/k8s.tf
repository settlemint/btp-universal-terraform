# Kubernetes mode: Deploy Keycloak via Bitnami Helm chart
resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = coalesce(try(var.k8s.namespace, null), var.namespace) }
}

locals {
  k8s_ns      = coalesce(try(var.k8s.namespace, null), var.namespace)
  k8s_release = var.k8s.release_name
  admin_password = coalesce(
    try(var.k8s.admin_password, null),
    try(var.secrets.admin_password, null)
  )
}

resource "helm_release" "keycloak" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.k8s_release
  namespace       = local.k8s_ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "keycloak"
  version         = var.k8s.chart_version
  atomic          = true
  cleanup_on_fail = true
  replace         = true
  timeout         = 600

  values = [
    yamlencode(merge({
      auth = {
        adminUser     = "admin"
        adminPassword = local.admin_password
      },
      production = false,
      postgresql = { enabled = true },
      proxy      = "edge",
      extraEnvVars = [
        { name = "KC_PROXY", value = "edge" }
      ],
      httpRelativePath = "/",
      service          = { type = "ClusterIP" },
      persistence      = { enabled = false }
      }, var.k8s.ingress_enabled ? {
      ingress = {
        enabled          = true,
        hostname         = "keycloak.${var.base_domain}",
        ingressClassName = "nginx"
      }
    } : {}, var.k8s.values))
  ]
}

locals {
  k8s_svc_host      = "${local.k8s_release}.${local.k8s_ns}.svc.cluster.local"
  k8s_http_url      = var.mode == "k8s" ? (var.k8s.ingress_enabled ? "http://keycloak.${var.base_domain}" : "http://${local.k8s_svc_host}:8080") : null
  k8s_issuer        = var.mode == "k8s" ? "${local.k8s_http_url}/realms/master" : null
  k8s_admin_url     = var.mode == "k8s" ? local.k8s_http_url : null
  k8s_client_id     = var.mode == "k8s" ? null : null
  k8s_client_secret = var.mode == "k8s" ? null : null
  k8s_scopes        = var.mode == "k8s" ? [] : null
  k8s_callback_urls = var.mode == "k8s" ? [] : null
}
