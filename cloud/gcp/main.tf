locals {
  network = {
    network_id         = null
    subnet_ids         = []
    private_subnet_ids = []
    public_subnet_ids  = []
  }

  security_groups = {}

  k8s_context = {
    network_id               = null
    subnet_ids               = []
    control_plane_subnet_ids = []
    firewall_rule_ids        = []
  }

  dependency_context = {}
}
