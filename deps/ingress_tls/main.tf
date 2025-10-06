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

# Wait for cert-manager CRDs to be installed
resource "time_sleep" "wait_for_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "60s"
}

# Create ClusterIssuer using kubectl via null_resource
# NOTE: We use null_resource instead of kubernetes_manifest because:
# 1. kubernetes_manifest requires K8s API connection during plan phase
# 2. The cluster doesn't exist yet during initial plan
# 3. This would cause "cannot create REST client: no client config" errors
# The null_resource approach runs during apply phase when cluster is ready
resource "null_resource" "selfsigned_issuer" {
  depends_on = [time_sleep.wait_for_cert_manager]

  triggers = {
    issuer_name     = var.issuer_name
    kubeconfig_path = var.kubeconfig_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${self.triggers.issuer_name}
spec:
  selfSigned: {}
EOF
    EOT
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      kubectl delete clusterissuer ${self.triggers.issuer_name} --ignore-not-found=true 2>/dev/null || true
    EOT
  }
}
