resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  ns      = var.namespace
  release = var.release_name
}

resource "helm_release" "vault" {
  name            = local.release
  namespace       = local.ns
  repository      = "https://helm.releases.hashicorp.com"
  chart           = "vault"
  version         = var.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      server = {
        dev         = { enabled = var.dev_mode }
        dataStorage = { enabled = false }
        service     = { type = "ClusterIP" }
      }
    }, var.values))
  ]
}

locals {
  vault_addr = "http://${local.release}.${local.ns}.svc.cluster.local:8200"
  token      = var.dev_mode ? coalesce(var.dev_token, "root") : null
}
