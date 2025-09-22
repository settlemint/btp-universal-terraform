resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "admin" { length = 20 }

locals {
  ns      = var.namespace
  release = var.release_name
}

resource "helm_release" "keycloak" {
  name            = local.release
  namespace       = local.ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "keycloak"
  version         = var.chart_version
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = [
    yamlencode(merge({
      auth = {
        adminUser     = "admin"
        adminPassword = random_password.admin.result
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
      }, var.ingress_enabled ? {
      ingress = {
        enabled          = true,
        hostname         = "keycloak.${var.base_domain}",
        ingressClassName = "nginx"
      }
    } : {}, var.values))
  ]
}

locals {
  svc_host   = "${local.release}.${local.ns}.svc.cluster.local"
  http_url   = var.ingress_enabled ? "http://keycloak.${var.base_domain}" : "http://${local.svc_host}:8080"
  issuer_url = "${local.http_url}/realms/master"
}
