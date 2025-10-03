platform = "generic"

cluster = {
  create          = false
  kubeconfig_path = null # use current context or ~/.kube/config
}

base_domain = "127.0.0.1.nip.io"

namespaces = {
  ingress_tls    = "btp-deps"
  postgres       = "btp-deps"
  redis          = "btp-deps"
  object_storage = "btp-deps"
  metrics_logs   = "btp-deps"
  oauth          = "btp-deps"
  secrets        = "btp-deps"
}

postgres = {
  mode = "k8s"
  k8s = {
    release_name           = "postgres"
    operator_chart_version = "1.12.2"
    postgresql_version     = "15"
    database               = "btp"
  }
}

redis = {
  mode = "k8s"
  k8s = {
    release_name  = "redis"
    chart_version = "18.1.6"
  }
}

object_storage = {
  mode = "k8s"
  k8s = {
    release_name   = "minio"
    chart_version  = "14.6.7"
    default_bucket = "btp-artifacts"
  }
}

ingress_tls = {
  mode = "k8s"
  k8s = {
    release_name_nginx         = "ingress"
    release_name_cert_manager  = "cert-manager"
    nginx_chart_version        = "4.10.1"
    cert_manager_chart_version = "v1.14.4"
    issuer_name                = "selfsigned-issuer"
  }
}

metrics_logs = {
  mode = "k8s"
  k8s = {
    release_name_kps         = "kps"
    release_name_loki        = "loki"
    kp_stack_chart_version   = "55.8.2"
    loki_stack_chart_version = "2.9.11"
  }
}

# Skip oauth for now to test BTP platform
# oauth = {
#   mode = "k8s" 
#   k8s = {
#     release_name  = "keycloak"
#     chart_version = "24.8.1"
#   }
# }

secrets = {
  mode = "k8s"
  k8s = {
    release_name  = "vault"
    chart_version = "0.27.0"
    dev_mode      = true
  }
}

btp = {
  enabled       = true
  chart         = "oci://harbor.settlemint.com/settlemint/settlemint"
  namespace     = "settlemint"
  release_name  = "settlemint-platform"
  chart_version = "v7.32.3"
  values_file   = "enhanced-dev-values.yaml"
}
