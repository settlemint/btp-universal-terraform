locals {
  network = {
    vnet_id            = null
    vnet_cidr          = null
    private_subnet_ids = []
    public_subnet_ids  = []
    nat_gateway_ids    = []
  }

  security_groups = {}

  k8s_context = {
    vnet_id                  = null
    subnet_ids               = []
    control_plane_subnet_ids = []
    security_group_ids       = []
  }

  dependency_context = {}
}
