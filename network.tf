data "openstack_networking_network_v2" "public_network" {
  network_id = var.external_network_id
}

resource "openstack_networking_network_v2" "rke2_network" {
  name = "rke2-network"
}

resource "openstack_networking_subnet_v2" "rke2_subnet" {
  name            = "rke2-subnet"
  network_id      = openstack_networking_network_v2.rke2_network.id
  cidr            = "10.0.1.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

resource "openstack_networking_router_v2" "rke2_router" {
  name                = "rke2_router"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "router_link" {
  router_id = openstack_networking_router_v2.rke2_router.id
  subnet_id = openstack_networking_subnet_v2.rke2_subnet.id
}
