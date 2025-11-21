# GCP mode: Deploy GCS bucket

locals {
  gcp_manage_bucket       = var.mode == "gcp" ? try(var.gcp.manage_bucket, true) : false
  gcp_bucket_name_raw     = var.mode == "gcp" ? try(var.gcp.bucket_name, null) : null
  gcp_bucket_name_input   = var.mode == "gcp" ? (local.gcp_bucket_name_raw != null ? trimspace(local.gcp_bucket_name_raw) : "") : ""
  gcp_base_domain_trimmed = var.mode == "gcp" ? trimspace(try(var.base_domain, "")) : ""
  gcp_bucket_seed         = var.mode == "gcp" ? (length(local.gcp_base_domain_trimmed) > 0 ? local.gcp_base_domain_trimmed : "btp") : ""
  gcp_should_generate_bucket = (
    var.mode == "gcp" &&
    local.gcp_manage_bucket &&
    length(local.gcp_bucket_name_input) == 0
  )
}

resource "random_id" "gcp_bucket_suffix" {
  count       = local.gcp_should_generate_bucket ? 1 : 0
  byte_length = 4

  keepers = {
    seed = local.gcp_bucket_seed
  }
}

locals {
  gcp_bucket_suffix_generated = local.gcp_should_generate_bucket ? substr(try(random_id.gcp_bucket_suffix[0].hex, md5(local.gcp_bucket_seed)), 0, 10) : ""
  gcp_bucket_name_effective = var.mode == "gcp" ? (
    length(local.gcp_bucket_name_input) > 0 ? local.gcp_bucket_name_input :
    (local.gcp_should_generate_bucket ? format("btp-%s-artifacts", local.gcp_bucket_suffix_generated) : null)
  ) : null

  gcp_identity_base = var.mode == "gcp" ? (
    local.gcp_bucket_name_effective != null ?
    replace(local.gcp_bucket_name_effective, ".", "-") :
    "btp-artifacts"
  ) : null

  gcp_service_account_name = local.gcp_identity_base != null ? "${local.gcp_identity_base}-sa" : "btp-artifacts-sa"
}

# Service account for bucket access
resource "google_service_account" "bucket" {
  count        = var.mode == "gcp" && local.gcp_manage_bucket ? 1 : 0
  project      = var.gcp.project_id
  account_id   = local.gcp_service_account_name
  display_name = "Service Account for ${local.gcp_bucket_name_effective}"
}

# Cloud Storage bucket
resource "google_storage_bucket" "bucket" {
  count    = var.mode == "gcp" && local.gcp_manage_bucket ? 1 : 0
  project  = var.gcp.project_id
  name     = local.gcp_bucket_name_effective
  location = var.gcp.location

  storage_class               = var.gcp.storage_class
  uniform_bucket_level_access = var.gcp.uniform_bucket_level_access
  force_destroy               = var.gcp.force_destroy

  # Versioning
  dynamic "versioning" {
    for_each = var.gcp.versioning_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.gcp.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = var.gcp.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.gcp.kms_key_name
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = var.gcp.cors_rules
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  labels = merge(
    {
      managed_by = "terraform"
      service    = "object-storage"
    },
    var.gcp.labels
  )
}

# IAM binding for service account
resource "google_storage_bucket_iam_member" "bucket_admin" {
  count  = var.mode == "gcp" && local.gcp_manage_bucket ? 1 : 0
  bucket = google_storage_bucket.bucket[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.bucket[0].email}"
}

# Create HMAC keys for S3-compatible access using gcloud (workaround for permission issues)
resource "null_resource" "hmac_key" {
  count = var.mode == "gcp" && local.gcp_manage_bucket ? 1 : 0

  triggers = {
    service_account = google_service_account.bucket[0].email
    project         = google_storage_bucket.bucket[0].project
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud storage hmac create ${google_service_account.bucket[0].email} \
        --project=${google_storage_bucket.bucket[0].project} \
        --format=json > ${path.module}/hmac_key_${google_storage_bucket.bucket[0].project}.json
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      ACCESS_ID=$(cat ${path.module}/hmac_key_${self.triggers.project}.json | jq -r '.metadata.accessId')
      gcloud storage hmac update $ACCESS_ID --deactivate --project=${self.triggers.project} || true
      gcloud storage hmac delete $ACCESS_ID --project=${self.triggers.project} || true
      rm -f ${path.module}/hmac_key_${self.triggers.project}.json
    EOT
  }
}

data "local_file" "hmac_key" {
  count      = var.mode == "gcp" && local.gcp_manage_bucket ? 1 : 0
  filename   = "${path.module}/hmac_key_${google_storage_bucket.bucket[0].project}.json"
  depends_on = [null_resource.hmac_key]
}

locals {
  # GCS can be accessed via S3-compatible API with HMAC keys
  gcp_endpoint   = var.mode == "gcp" ? "https://storage.googleapis.com" : null
  gcp_bucket     = var.mode == "gcp" ? (local.gcp_manage_bucket ? google_storage_bucket.bucket[0].name : local.gcp_bucket_name_effective) : null
  gcp_hmac_data  = var.mode == "gcp" && local.gcp_manage_bucket ? jsondecode(data.local_file.hmac_key[0].content) : null
  gcp_access_key = var.mode == "gcp" && local.gcp_manage_bucket ? local.gcp_hmac_data.metadata.accessId : var.gcp.access_key
  gcp_secret_key = var.mode == "gcp" && local.gcp_manage_bucket ? local.gcp_hmac_data.secret : var.gcp.secret_key
  gcp_region         = var.mode == "gcp" ? var.gcp.location : null
  gcp_use_path_style = var.mode == "gcp" ? false : null
}
