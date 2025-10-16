# Kubernetes mode: Deploy Redis via Bitnami Helm chart
resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = coalesce(try(var.k8s.namespace, null), var.namespace) }
}

locals {
  k8s_release = var.k8s.release_name
  k8s_ns      = coalesce(try(var.k8s.namespace, null), var.namespace)
  resolved_k8s_password = coalesce(
    try(var.k8s.password, null),
    try(var.secrets.password, null)
  )
}

resource "helm_release" "redis" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.k8s_release
  namespace       = local.k8s_ns
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "redis"
  version         = var.k8s.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      architecture = "standalone",
      auth = {
        enabled  = true,
        password = local.k8s_password
      },
      master = {
        persistence = { enabled = false }
      }
    }, var.k8s.values))
  ]
}

locals {
  k8s_host        = var.mode == "k8s" ? "${local.k8s_release}-master.${local.k8s_ns}.svc.cluster.local" : null
  k8s_port        = var.mode == "k8s" ? 6379 : null
  k8s_password    = var.mode == "k8s" ? local.resolved_k8s_password : null
  k8s_scheme      = var.mode == "k8s" ? "redis" : null
  k8s_tls_enabled = var.mode == "k8s" ? false : null
}
