# Placeholder module for the SettleMint BTP Helm release.
# This will be wired once the chart details and value mapping are finalized.

resource "kubernetes_namespace" "btp" {
  metadata { name = var.namespace }
}

# TODO: helm_release for BTP chart using normalized dependency inputs.

