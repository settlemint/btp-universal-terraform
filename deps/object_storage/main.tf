resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "secret" {
  count  = var.secret_key == null ? 1 : 0
  length = 30
}

locals {
  release = var.release_name
  ns      = var.namespace
}

resource "helm_release" "minio" {
  name            = local.release
  namespace       = local.ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "minio"
  version         = var.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      auth = {
        rootUser     = coalesce(var.access_key, "minio")
        rootPassword = coalesce(var.secret_key, try(random_password.secret[0].result, null))
      },
      defaultBuckets = var.default_bucket,
      persistence    = { enabled = false },
      service        = { type = "ClusterIP" }
    }, var.values))
  ]
}

locals {
  endpoint = "http://${local.release}.${local.ns}.svc.cluster.local:9000"
}
