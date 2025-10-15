# SettleMint Platform (Helm) deployment configuration

variable "btp" {
  description = "Configure deployment of the SettleMint Platform Helm chart (disabled by default)."
  type = object({
    enabled              = optional(bool, false)
    namespace            = optional(string, "settlemint")
    deployment_namespace = optional(string, "deployments")
    release_name         = optional(string, "settlemint-platform")
    chart                = optional(string, "oci://registry.settlemint.com/settlemint-platform/SettleMint")
    chart_version        = optional(string)
    values               = optional(map(any), {})
    values_file          = optional(string)
  })
  default = {}
}
