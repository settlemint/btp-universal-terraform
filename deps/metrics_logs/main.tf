resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  ns           = var.namespace
  release_kps  = var.release_name_kps
  release_loki = var.release_name_loki
}

resource "helm_release" "kps" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.release_kps
  namespace       = local.ns
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "kube-prometheus-stack"
  version         = var.kp_stack_chart_version
  atomic          = true
  cleanup_on_fail = true

  values = var.mode == "k8s" ? [
    yamlencode(merge({
      grafana = {
        adminPassword = var.grafana_password
        persistence   = { enabled = false }
        service       = { type = "ClusterIP" }
      },
      prometheus = {
        prometheusSpec = { retention = "24h" }
      }
    }, var.values))
  ] : []

  # Ensure we destroy helm releases before cluster/namespace
  lifecycle {
    create_before_destroy = false
  }
}

resource "helm_release" "loki" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.release_loki
  namespace       = local.ns
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "loki-stack"
  version         = var.loki_stack_chart_version
  atomic          = true
  cleanup_on_fail = true

  values = var.mode == "k8s" ? [
    yamlencode({
      grafana  = { enabled = false },
      promtail = { enabled = true },
      loki     = { persistence = { enabled = false } }
    })
  ] : []

  # Ensure we destroy helm releases before cluster/namespace
  lifecycle {
    create_before_destroy = false
  }
}

locals {
  grafana_svc    = var.mode == "k8s" ? "${local.release_kps}-grafana.${local.ns}.svc.cluster.local" : null
  grafana_url    = var.mode == "k8s" ? "http://${local.grafana_svc}" : null
  prometheus_url = var.mode == "k8s" ? "http://${local.release_kps}-prometheus.${local.ns}.svc.cluster.local:9090" : null
  loki_url       = var.mode == "k8s" ? "http://${local.release_loki}.${local.ns}.svc.cluster.local:3100" : null
}
