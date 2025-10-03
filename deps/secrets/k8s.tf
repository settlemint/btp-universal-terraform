# Kubernetes mode: Deploy Vault via Helm
resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  k8s_ns      = var.namespace
  k8s_release = var.k8s.release_name
}

resource "helm_release" "vault" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = local.k8s_release
  namespace       = local.k8s_ns
  repository      = "https://helm.releases.hashicorp.com"
  chart           = "vault"
  version         = var.k8s.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      server = {
        dev         = { enabled = var.k8s.dev_mode }
        dataStorage = { enabled = false }
        service     = { type = "ClusterIP" }
      }
    }, var.k8s.values))
  ]
}

locals {
  k8s_vault_addr = var.mode == "k8s" ? "http://${local.k8s_release}.${local.k8s_ns}.svc.cluster.local:8200" : null
  k8s_token      = var.mode == "k8s" && var.k8s.dev_mode ? coalesce(var.k8s.dev_token, "root") : null
  k8s_kv_mount   = var.mode == "k8s" ? "secret" : null
  k8s_paths      = var.mode == "k8s" ? [] : null
}
