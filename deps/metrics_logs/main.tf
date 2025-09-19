resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "grafana" { length = 16 }

locals {
  ns           = var.namespace
  release_kps  = var.release_name_kps
  release_loki = var.release_name_loki
}

resource "helm_release" "kps" {
  name       = local.release_kps
  namespace  = local.ns
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kp_stack_chart_version

  values = [
    yamlencode(merge({
      grafana = {
        adminPassword = random_password.grafana.result
        persistence   = { enabled = false }
        service       = { type = "ClusterIP" }
      },
      prometheus = {
        prometheusSpec = { retention = "24h" }
      }
    }, var.values))
  ]
}

resource "helm_release" "loki" {
  name       = local.release_loki
  namespace  = local.ns
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.loki_stack_chart_version

  values = [
    yamlencode({
      grafana  = { enabled = false },
      promtail = { enabled = true },
      loki     = { persistence = { enabled = false } }
    })
  ]
}

locals {
  grafana_svc    = "${local.release_kps}-grafana.${local.ns}.svc.cluster.local"
  grafana_url    = "http://${local.grafana_svc}"
  prometheus_url = "http://${local.release_kps}-prometheus.${local.ns}.svc.cluster.local:9090"
  loki_url       = "http://${local.release_loki}.${local.ns}.svc.cluster.local:3100"
}
