variable "mode" {
  type        = string
  description = "Deployment mode: k8s | aws | azure | gcp | byo"
  default     = "k8s"
  validation {
    condition     = contains(["k8s", "aws", "azure", "gcp", "byo"], var.mode)
    error_message = "Mode must be one of: k8s, aws, azure, gcp, byo"
  }
}

variable "aws" {
  type = object({
    # VPC Creation
    create_vpc         = optional(bool, true)
    vpc_name           = optional(string, "btp-vpc")
    vpc_cidr           = optional(string, "10.0.0.0/16")
    region             = optional(string, "us-east-1")
    availability_zones = optional(list(string), ["us-east-1a", "us-east-1b", "us-east-1c"])

    # NAT Gateway Configuration
    enable_nat_gateway = optional(bool, true)
    single_nat_gateway = optional(bool, true) # Set to false for HA (more expensive)

    # VPC Endpoints
    enable_s3_endpoint = optional(bool, true)

    # Security Groups
    additional_security_group_ids = optional(list(string), [])

    # Use existing VPC instead of creating new one
    existing_vpc_id                        = optional(string)
    existing_private_subnet_ids            = optional(list(string), [])
    existing_public_subnet_ids             = optional(list(string), [])
    existing_rds_security_group_id         = optional(string)
    existing_elasticache_security_group_id = optional(string)
  })
  default     = {}
  description = "AWS VPC configuration"
}
