# TFLint configuration for Terraform + Helm/Kubernetes repository

# Core Terraform rules
rule "terraform_required_providers"    { enabled = true }
rule "terraform_required_version"      { enabled = true }
rule "terraform_unused_declarations"   { enabled = true }
rule "terraform_standard_module_structure" { enabled = true }
rule "terraform_typed_variables"       { enabled = true }

# Cloud rulesets can be enabled per-cloud directory when added.
