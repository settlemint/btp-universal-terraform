# Kubernetes mode: Deploy MinIO via Bitnami Helm chart
resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = coalesce(try(var.k8s.namespace, null), var.namespace) }
}

locals {
  k8s_release         = var.k8s.release_name
  k8s_ns              = coalesce(try(var.k8s.namespace, null), var.namespace)
  resolved_access_key = coalesce(try(var.k8s.access_key, null), try(var.secrets.access_key, null), "minio")
  resolved_secret_key = coalesce(try(var.k8s.secret_key, null), try(var.secrets.secret_key, null), "minio123")
}

resource "helm_release" "minio" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.k8s_release
  namespace       = local.k8s_ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "minio"
  version         = var.k8s.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      auth = {
        rootUser     = local.resolved_access_key
        rootPassword = local.resolved_secret_key
      },
      defaultBuckets = var.k8s.default_bucket,
      persistence    = { enabled = false },
      service        = { type = "ClusterIP" }
    }, var.k8s.values))
  ]
}

locals {
  k8s_endpoint       = var.mode == "k8s" ? "http://${local.k8s_release}.${local.k8s_ns}.svc.cluster.local:9000" : null
  k8s_bucket         = var.mode == "k8s" ? var.k8s.default_bucket : null
  k8s_access_key     = var.mode == "k8s" ? local.resolved_access_key : null
  k8s_secret_key     = var.mode == "k8s" ? local.resolved_secret_key : null
  k8s_region         = var.mode == "k8s" ? "us-east-1" : null
  k8s_use_path_style = var.mode == "k8s" ? true : null
}
