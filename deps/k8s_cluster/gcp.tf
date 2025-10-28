# GCP GKE Cluster Implementation

# Data source to get available GKE versions
data "google_container_engine_versions" "gke_versions" {
  count          = var.mode == "gcp" ? 1 : 0
  location       = var.gcp.region
  project        = var.gcp.project_id
  version_prefix = var.gcp.kubernetes_version != null ? "${var.gcp.kubernetes_version}." : null
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  count        = var.mode == "gcp" ? 1 : 0
  project      = var.gcp.project_id
  account_id   = "${var.gcp.cluster_name}-nodes"
  display_name = "Service Account for ${var.gcp.cluster_name} GKE nodes"
}

# IAM bindings for node service account
resource "google_project_iam_member" "gke_nodes_log_writer" {
  count   = var.mode == "gcp" ? 1 : 0
  project = var.gcp.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  count   = var.mode == "gcp" ? 1 : 0
  project = var.gcp.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  count   = var.mode == "gcp" ? 1 : 0
  project = var.gcp.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_gcr" {
  count   = var.mode == "gcp" ? 1 : 0
  project = var.gcp.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

# GKE Cluster
resource "google_container_cluster" "main" {
  count    = var.mode == "gcp" ? 1 : 0
  project  = var.gcp.project_id
  name     = var.gcp.cluster_name
  location = var.gcp.region

  # Use specified version or latest from stable channel
  min_master_version = var.gcp.kubernetes_version != null ? data.google_container_engine_versions.gke_versions[0].latest_master_version : null
  release_channel {
    channel = "STABLE"
  }

  # Network configuration
  network    = var.gcp.network
  subnetwork = var.gcp.subnetwork

  # IP allocation policy for pods and services
  dynamic "ip_allocation_policy" {
    for_each = var.gcp.ip_allocation_policy != null ? [var.gcp.ip_allocation_policy] : []
    content {
      cluster_secondary_range_name  = lookup(ip_allocation_policy.value, "cluster_secondary_range_name", null)
      services_secondary_range_name = lookup(ip_allocation_policy.value, "services_secondary_range_name", null)
      cluster_ipv4_cidr_block       = lookup(ip_allocation_policy.value, "cluster_ipv4_cidr_block", null)
      services_ipv4_cidr_block      = lookup(ip_allocation_policy.value, "services_ipv4_cidr_block", null)
    }
  }

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.gcp.enable_private_nodes || var.gcp.enable_private_endpoint ? [1] : []
    content {
      enable_private_nodes    = var.gcp.enable_private_nodes
      enable_private_endpoint = var.gcp.enable_private_endpoint
      master_ipv4_cidr_block  = var.gcp.master_ipv4_cidr_block
    }
  }

  # Workload Identity
  dynamic "workload_identity_config" {
    for_each = var.gcp.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.gcp.project_id}.svc.id.goog"
    }
  }

  # Remove default node pool
  remove_default_node_pool = var.gcp.remove_default_node_pool
  initial_node_count       = var.gcp.initial_node_count

  # Addons
  addons_config {
    http_load_balancing {
      disabled = !var.gcp.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.gcp.enable_horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = !var.gcp.enable_network_policy
    }
  }

  # Network policy
  dynamic "network_policy" {
    for_each = var.gcp.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "PROVIDER_UNSPECIFIED"
    }
  }

  # Monitoring and logging
  logging_service    = var.gcp.enable_cloud_logging ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service = var.gcp.enable_cloud_monitoring ? "monitoring.googleapis.com/kubernetes" : "none"

  # Resource labels
  resource_labels = merge(
    {
      managed_by = "terraform"
      cluster    = var.gcp.cluster_name
    },
    var.gcp.resource_labels
  )

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Enable shielded nodes
  enable_shielded_nodes = true

  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count
    ]
  }
}

# Node pools
resource "google_container_node_pool" "pools" {
  for_each = var.mode == "gcp" ? var.gcp.node_pools : {}

  project    = var.gcp.project_id
  name       = each.key
  location   = var.gcp.region
  cluster    = google_container_cluster.main[0].name
  node_count = each.value.auto_scaling ? null : each.value.node_count

  # Autoscaling configuration
  dynamic "autoscaling" {
    for_each = each.value.auto_scaling ? [1] : []
    content {
      min_node_count = each.value.min_node_count
      max_node_count = each.value.max_node_count
    }
  }

  # Node configuration
  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    preemptible  = each.value.preemptible
    spot         = each.value.spot

    service_account = google_service_account.gke_nodes[0].email
    oauth_scopes    = each.value.oauth_scopes

    labels = merge(
      {
        managed_by = "terraform"
        cluster    = var.gcp.cluster_name
        pool       = each.key
      },
      each.value.node_labels
    )

    dynamic "taint" {
      for_each = each.value.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    dynamic "workload_metadata_config" {
      for_each = var.gcp.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Generate kubeconfig
locals {
  gcp_cluster_name     = var.mode == "gcp" ? google_container_cluster.main[0].name : null
  gcp_cluster_endpoint = var.mode == "gcp" ? "https://${google_container_cluster.main[0].endpoint}" : null
  gcp_cluster_ca_cert  = var.mode == "gcp" ? google_container_cluster.main[0].master_auth[0].cluster_ca_certificate : null
  gcp_cluster_version  = var.mode == "gcp" ? google_container_cluster.main[0].master_version : null

  # Generate kubeconfig with gcloud authentication
  gcp_kubeconfig = var.mode == "gcp" ? yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = google_container_cluster.main[0].name
      cluster = {
        server                     = "https://${google_container_cluster.main[0].endpoint}"
        certificate-authority-data = google_container_cluster.main[0].master_auth[0].cluster_ca_certificate
      }
    }]
    contexts = [{
      name = google_container_cluster.main[0].name
      context = {
        cluster = google_container_cluster.main[0].name
        user    = google_container_cluster.main[0].name
      }
    }]
    current-context = google_container_cluster.main[0].name
    users = [{
      name = google_container_cluster.main[0].name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "gcloud"
          args = [
            "container",
            "clusters",
            "get-credentials",
            google_container_cluster.main[0].name,
            "--region",
            var.gcp.region,
            "--project",
            var.gcp.project_id
          ]
          interactiveMode    = "Never"
          provideClusterInfo = true
        }
      }
    }]
  }) : null

  gcp_provider_exec = var.mode == "gcp" ? [{
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gcloud"
    args = [
      "container",
      "clusters",
      "get-credentials",
      google_container_cluster.main[0].name,
      "--region",
      var.gcp.region,
      "--project",
      var.gcp.project_id
    ]
  }] : []
}
