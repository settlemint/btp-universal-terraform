# Kubernetes mode: Deploy Redis via Bitnami Helm chart
resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "redis" {
  count   = var.mode == "k8s" && var.k8s.password == null ? 1 : 0
  length  = 24
  special = false
}

locals {
  k8s_release = var.k8s.release_name
  k8s_ns      = var.namespace
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
        password = coalesce(var.k8s.password, try(random_password.redis[0].result, null))
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
  k8s_password    = var.mode == "k8s" ? coalesce(var.k8s.password, try(random_password.redis[0].result, null)) : null
  k8s_scheme      = var.mode == "k8s" ? "redis" : null
  k8s_tls_enabled = var.mode == "k8s" ? false : null
}
