variable "vpc" {
  description = "AWS VPC configuration used to bootstrap networking for dependencies."
  type = object({
    create_vpc                             = optional(bool, true)
    vpc_name                               = optional(string, "btp-vpc")
    vpc_cidr                               = optional(string, "10.0.0.0/16")
    region                                 = optional(string, "us-east-1")
    availability_zones                     = optional(list(string), ["us-east-1a", "us-east-1b", "us-east-1c"])
    enable_nat_gateway                     = optional(bool, true)
    single_nat_gateway                     = optional(bool, true)
    enable_s3_endpoint                     = optional(bool, true)
    additional_security_group_ids          = optional(list(string), [])
    existing_vpc_id                        = optional(string)
    existing_private_subnet_ids            = optional(list(string), [])
    existing_public_subnet_ids             = optional(list(string), [])
    existing_rds_security_group_id         = optional(string)
    existing_elasticache_security_group_id = optional(string)
  })
  default = {}
}
