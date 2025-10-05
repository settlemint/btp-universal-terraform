resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "helm_release" "ingress_nginx" {
  name            = var.release_name_nginx
  namespace       = var.namespace
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  version         = var.nginx_chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(merge({
      controller = {
        ingressClassResource = { name = "nginx", default = true }
        service              = { type = "NodePort" }
      }
    }, var.values_nginx))
  ]
}

resource "helm_release" "cert_manager" {
  name            = var.release_name_cert_manager
  namespace       = var.namespace
  repository      = "https://charts.jetstack.io"
  chart           = "cert-manager"
  version         = var.cert_manager_chart_version
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode(merge({
      installCRDs = true
    }, var.values_cert_manager))
  ]
}

resource "time_sleep" "cert_manager_crds" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "90s"
}

resource "kubernetes_manifest" "selfsigned_issuer" {
  depends_on = [time_sleep.cert_manager_crds]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.issuer_name
    }
    spec = {
      selfSigned = {}
    }
  }
}
