# BYO (Bring Your Own) Kubernetes Cluster
# Uses existing kubeconfig to connect to a cluster

# Read kubeconfig from file if path is provided
locals {
  byo_kubeconfig_raw = var.mode == "byo" && var.byo != null ? (
    var.byo.kubeconfig_content != null ? base64decode(var.byo.kubeconfig_content) : (
      var.byo.kubeconfig_path != null ? file(var.byo.kubeconfig_path) : null
    )
  ) : null

  byo_kubeconfig = var.mode == "byo" && local.byo_kubeconfig_raw != null ? yamldecode(local.byo_kubeconfig_raw) : null

  # Extract cluster information from kubeconfig
  byo_context_name = var.mode == "byo" && var.byo != null ? (
    var.byo.context_name != null ? var.byo.context_name : try(local.byo_kubeconfig["current-context"], null)
  ) : null

  byo_context = var.mode == "byo" && local.byo_kubeconfig != null ? (
    try([for ctx in local.byo_kubeconfig["contexts"] : ctx if ctx.name == local.byo_context_name][0].context, null)
  ) : null

  byo_cluster_info = var.mode == "byo" && local.byo_kubeconfig != null && local.byo_context != null ? (
    try([for cluster in local.byo_kubeconfig["clusters"] : cluster if cluster.name == local.byo_context.cluster][0].cluster, null)
  ) : null

  # Outputs for BYO mode
  byo_cluster_name      = var.mode == "byo" ? try(local.byo_context.cluster, "byo-cluster") : null
  byo_cluster_endpoint  = var.mode == "byo" ? try(local.byo_cluster_info.server, null) : null
  byo_cluster_ca_cert   = var.mode == "byo" ? try(local.byo_cluster_info["certificate-authority-data"], null) : null
  byo_cluster_version   = var.mode == "byo" ? "unknown" : null
  byo_kubeconfig_output = var.mode == "byo" ? local.byo_kubeconfig_raw : null
}
