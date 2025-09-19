resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "random_password" "postgres" {
  length  = 24
  special = true
}

locals {
  release = var.release_name
  ns      = var.namespace
}

resource "helm_release" "postgres" {
  name       = local.release
  namespace  = local.ns
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = var.chart_version

  values = [
    yamlencode(merge({
      global = {
        postgresql = {
          auth = {
            postgresPassword = random_password.postgres.result
            database         = var.database
          }
        }
      }
      primary = {
        persistence = { enabled = false }
        service     = { type = "ClusterIP" }
      }
    }, var.values))
  ]
}

locals {
  host = "${local.release}-postgresql.${local.ns}.svc.cluster.local"
  port = 5432
  user = "postgres"
}
