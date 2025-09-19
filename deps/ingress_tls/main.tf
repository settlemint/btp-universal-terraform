resource "kubernetes_namespace" "this" {
  count = var.manage_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "helm_release" "ingress_nginx" {
  name       = var.release_name_nginx
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_chart_version

  values = [
    yamlencode({
      controller = {
        ingressClassResource = { name = "nginx", default = true }
        service              = { type = "NodePort" }
      }
    })
  ]
}

resource "helm_release" "cert_manager" {
  name       = var.release_name_cert_manager
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  values = [
    yamlencode({
      installCRDs = true
    })
  ]
}

resource "kubectl_manifest" "selfsigned_issuer" {
  depends_on = [helm_release.cert_manager]
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${var.issuer_name}
spec:
  selfSigned: {}
YAML
}
