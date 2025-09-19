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
  name       = local.release
  namespace  = local.ns
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = var.chart_version

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
    }, var.values))
  ]
}

locals {
  svc_host   = "${local.release}.${local.ns}.svc.cluster.local"
  http_url   = "http://${local.svc_host}:8080"
  issuer_url = "${local.http_url}/realms/master"
}
