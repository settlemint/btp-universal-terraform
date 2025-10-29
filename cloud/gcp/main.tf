# GCP VPC Network Module
# Creates VPC, subnets, Cloud NAT, and firewall rules for GKE and managed services

locals {
  vpc_defaults = {
    create_vpc              = true
    project_id              = null
    network_name            = "btp-network"
    region                  = "us-central1"
    routing_mode            = "REGIONAL"
    auto_create_subnetworks = false
    delete_default_routes   = false

    # Subnet configuration
    subnet_cidr   = "10.0.0.0/20"
    pods_cidr     = "10.4.0.0/14" # GKE pods secondary range
    services_cidr = "10.8.0.0/20" # GKE services secondary range

    # Cloud NAT
    enable_cloud_nat = true

    # Firewall
    allow_internal          = true
    allow_ssh_from_anywhere = false
    ssh_source_ranges       = []

    # Existing resources (BYO mode)
    existing_network_name = null
    existing_network_id   = null
    existing_subnet_name  = null
  }

  vpc_input  = merge(local.vpc_defaults, try(var.config, {}))
  create_vpc = local.vpc_input.create_vpc
}

# VPC Network
resource "google_compute_network" "main" {
  count                           = local.create_vpc ? 1 : 0
  project                         = local.vpc_input.project_id
  name                            = local.vpc_input.network_name
  auto_create_subnetworks         = local.vpc_input.auto_create_subnetworks
  routing_mode                    = local.vpc_input.routing_mode
  delete_default_routes_on_create = local.vpc_input.delete_default_routes
}

# Subnet for GKE and managed services
resource "google_compute_subnetwork" "main" {
  count         = local.create_vpc ? 1 : 0
  project       = local.vpc_input.project_id
  name          = "${local.vpc_input.network_name}-subnet"
  ip_cidr_range = local.vpc_input.subnet_cidr
  region        = local.vpc_input.region
  network       = google_compute_network.main[0].id

  # Secondary ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = local.vpc_input.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = local.vpc_input.services_cidr
  }

  private_ip_google_access = true
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  count   = local.create_vpc && local.vpc_input.enable_cloud_nat ? 1 : 0
  project = local.vpc_input.project_id
  name    = "${local.vpc_input.network_name}-router"
  region  = local.vpc_input.region
  network = google_compute_network.main[0].id
}

# Cloud NAT for private GKE nodes to access internet
resource "google_compute_router_nat" "nat" {
  count                              = local.create_vpc && local.vpc_input.enable_cloud_nat ? 1 : 0
  project                            = local.vpc_input.project_id
  name                               = "${local.vpc_input.network_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = local.vpc_input.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  count   = local.create_vpc && local.vpc_input.allow_internal ? 1 : 0
  project = local.vpc_input.project_id
  name    = "${local.vpc_input.network_name}-allow-internal"
  network = google_compute_network.main[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    local.vpc_input.subnet_cidr,
    local.vpc_input.pods_cidr,
    local.vpc_input.services_cidr
  ]
}

# Firewall rule: Allow SSH (optional)
resource "google_compute_firewall" "allow_ssh" {
  count   = local.create_vpc && local.vpc_input.allow_ssh_from_anywhere ? 1 : 0
  project = local.vpc_input.project_id
  name    = "${local.vpc_input.network_name}-allow-ssh"
  network = google_compute_network.main[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = length(local.vpc_input.ssh_source_ranges) > 0 ? local.vpc_input.ssh_source_ranges : ["0.0.0.0/0"]
}

# Data sources for existing network (BYO mode)
data "google_compute_network" "existing" {
  count   = !local.create_vpc && local.vpc_input.existing_network_name != null ? 1 : 0
  project = local.vpc_input.project_id
  name    = local.vpc_input.existing_network_name
}

data "google_compute_subnetwork" "existing" {
  count   = !local.create_vpc && local.vpc_input.existing_subnet_name != null ? 1 : 0
  project = local.vpc_input.project_id
  name    = local.vpc_input.existing_subnet_name
  region  = local.vpc_input.region
}

# Outputs
locals {
  network_name = local.create_vpc ? google_compute_network.main[0].name : (
    local.vpc_input.existing_network_name != null ? local.vpc_input.existing_network_name : "default"
  )

  network_id = local.create_vpc ? google_compute_network.main[0].id : (
    local.vpc_input.existing_network_id != null ? local.vpc_input.existing_network_id :
    (length(data.google_compute_network.existing) > 0 ? data.google_compute_network.existing[0].id : null)
  )

  subnet_name = local.create_vpc ? google_compute_subnetwork.main[0].name : (
    local.vpc_input.existing_subnet_name != null ? local.vpc_input.existing_subnet_name : "default"
  )

  network = {
    network_id         = local.network_id
    network_name       = local.network_name
    subnet_name        = local.subnet_name
    private_subnet_ids = local.create_vpc ? [google_compute_subnetwork.main[0].id] : []
    public_subnet_ids  = []
  }

  security_groups = {}

  k8s_context = {
    network_id               = local.network_id
    network_name             = local.network_name
    subnet_name              = local.subnet_name
    subnet_ids               = []
    control_plane_subnet_ids = []
    firewall_rule_ids = local.create_vpc ? concat(
      google_compute_firewall.allow_internal[*].id,
      google_compute_firewall.allow_ssh[*].id
    ) : []
  }

  dependency_context = {
    postgres = {
      network_name = local.network_name
    }
    redis = {
      network_name = local.network_name
    }
  }
}
