# TFLint configuration for Terraform + Helm/Kubernetes repository

# Core Terraform rule configuration
rule "terraform_required_providers" { enabled = true }
rule "terraform_required_version"   { enabled = true }
rule "terraform_unused_declarations" { enabled = true }

# Encourage standard module layout (main.tf, variables.tf, outputs.tf)
rule "terraform_standard_module_structure" { enabled = true }

# Require types on variables (HCL2 best practice)
rule "terraform_typed_variables" { enabled = true }


# Core terraform rules are enabled by default.
# Cloud rulesets are scaffolded and disabled; enable them per-cloud directory when added.

# Example of tailoring core rules
rule "terraform_required_providers" { enabled = true }
rule "terraform_required_version"   { enabled = true }
rule "terraform_unused_declarations" { enabled = true }
