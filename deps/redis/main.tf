resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "redis" {
  count   = var.password == null ? 1 : 0
  length  = 24
  special = false
}

locals {
  release = var.release_name
  ns      = var.namespace
}

resource "helm_release" "redis" {
  name            = local.release
  namespace       = local.ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "redis"
  version         = var.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      architecture = "standalone",
      auth = {
        enabled  = true,
        password = coalesce(var.password, try(random_password.redis[0].result, null))
      },
      master = {
        persistence = { enabled = false }
      }
    }, var.values))
  ]
}

locals {
  host = "${local.release}-master.${local.ns}.svc.cluster.local"
  port = 6379
}
