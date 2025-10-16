# Core helpers for all k8s cluster modes

locals {
  # Determine where kubeconfig should live based on mode
  kubeconfig_path = (
    var.mode == "byo" && var.byo != null && try(var.byo.kubeconfig_path, null) != null ?
    pathexpand(var.byo.kubeconfig_path) :
    contains(["aws", "azure", "gcp"], var.mode) ?
    "${path.root}/.terraform/kubeconfig-${var.mode}" :
    null
  )

  # Only managed clusters need us to write kubeconfig files
  write_kubeconfig = contains(["aws", "azure", "gcp"], var.mode)
}
