resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

locals {
  release = var.release_name
  ns      = var.namespace
}

# Wait for postgres operator to be ready and create secrets
resource "time_sleep" "wait_for_postgres_secret" {
  create_duration = "30s"
  
  depends_on = [kubernetes_manifest.postgres_cluster]
}

# Install Zalando Postgres Operator via Helm
resource "helm_release" "postgres_operator" {
  name            = "postgres-operator"
  namespace       = local.ns
  repository      = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart           = "postgres-operator"
  version         = var.operator_chart_version
  skip_crds       = false
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge(
      {
        configKubernetes = {
          # Set SSL mode for operator connections to match cluster SSL setting
          postgres_pod_environment_secret_sslmode = var.enable_ssl ? "require" : "disable"
        }
      },
      var.values
    ))
  ]
}

# Create a minimal Postgres cluster managed by the operator
resource "kubernetes_manifest" "postgres_cluster" {
  manifest = {
    apiVersion = "acid.zalan.do/v1"
    kind       = "postgresql"
    metadata = {
      name      = local.release
      namespace = local.ns
      labels = {
        "btp.smint.io/dependency" = "postgres"
      }
    }
    spec = {
      teamId            = "btp"
      numberOfInstances = 1
      volume            = { size = "1Gi" }
      users = {
        postgres = ["superuser"]
      }
      databases = {
        "${var.database}" = "postgres"
      }
      postgresql = {
        version = var.postgresql_version
        parameters = {
          ssl = var.enable_ssl ? "on" : "off"
        }
      }
      patroni = {
        pg_hba = var.pg_hba_rules
      }
    }
  }

  depends_on = [helm_release.postgres_operator]
}

locals {
  # Zalando operator exposes the primary service under the cluster name
  host = "${local.release}.${local.ns}.svc.cluster.local"
  port = 5432
  user = "postgres"
}

data "kubernetes_secret" "postgres" {
  metadata {
    name      = coalesce(var.credentials_secret_name_override, "${local.release}.postgres.credentials.postgresql.acid.zalan.do")
    namespace = local.ns
  }

  depends_on = [time_sleep.wait_for_postgres_secret]
}
