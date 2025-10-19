# Kubernetes mode: Deploy PostgreSQL via Zalando Postgres Operator
resource "kubernetes_namespace" "this" {
  count = var.mode == "k8s" && var.manage_namespace ? 1 : 0
  metadata { name = coalesce(try(var.k8s.namespace, null), var.namespace) }
}

locals {
  k8s_release                  = var.k8s.release_name
  k8s_ns                       = coalesce(try(var.k8s.namespace, null), var.namespace)
  postgres_secret_wait_seconds = 30
}

# Wait for postgres operator to be ready and create secrets
resource "time_sleep" "wait_for_postgres_secret" {
  count           = var.mode == "k8s" ? 1 : 0
  create_duration = "${local.postgres_secret_wait_seconds}s"

  depends_on = [kubernetes_manifest.postgres_cluster]
}

# Install Zalando Postgres Operator via Helm
resource "helm_release" "postgres_operator" {
  count           = var.mode == "k8s" ? 1 : 0
  name            = "postgres-operator"
  namespace       = local.k8s_ns
  repository      = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart           = "postgres-operator"
  version         = var.k8s.operator_chart_version
  skip_crds       = false
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge(
      {
        configKubernetes = {
          # Set SSL mode for operator connections to match cluster SSL setting
          postgres_pod_environment_secret_sslmode = var.k8s.enable_ssl ? "require" : "disable"
        }
      },
      var.k8s.values
    ))
  ]
}

# Create a minimal Postgres cluster managed by the operator
resource "kubernetes_manifest" "postgres_cluster" {
  count = var.mode == "k8s" ? 1 : 0
  manifest = {
    apiVersion = "acid.zalan.do/v1"
    kind       = "postgresql"
    metadata = {
      name      = local.k8s_release
      namespace = local.k8s_ns
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
        "${var.k8s.database}" = "postgres"
      }
      postgresql = {
        version = var.k8s.postgresql_version
        parameters = {
          ssl = var.k8s.enable_ssl ? "on" : "off"
        }
      }
      patroni = {
        pg_hba = var.k8s.pg_hba_rules
      }
    }
  }

  depends_on = [helm_release.postgres_operator]
}

data "kubernetes_secret" "postgres" {
  count = var.mode == "k8s" ? 1 : 0
  metadata {
    name      = coalesce(var.k8s.credentials_secret_name_override, "${local.k8s_release}.postgres.credentials.postgresql.acid.zalan.do")
    namespace = local.k8s_ns
  }

  depends_on = [time_sleep.wait_for_postgres_secret]
}

locals {
  k8s_host     = var.mode == "k8s" ? "${local.k8s_release}.${local.k8s_ns}.svc.cluster.local" : null
  k8s_port     = var.mode == "k8s" ? 5432 : null
  k8s_user     = var.mode == "k8s" ? "postgres" : null
  k8s_password = var.mode == "k8s" ? try(data.kubernetes_secret.postgres[0].data["password"], "") : null
  k8s_database = var.mode == "k8s" ? var.k8s.database : null
  k8s_ssl_mode = var.mode == "k8s" ? (var.k8s.enable_ssl ? "require" : "disable") : null
}
