resource "openstack_lb_loadbalancer_v2" "k8s_nlb" {
  name          = "rke2-nlb"
  vip_subnet_id = openstack_networking_subnet_v2.rke2_subnet.id
}

resource "openstack_lb_listener_v2" "k8s_api_listener" {
  name            = "k8s-api-listener"
  protocol        = "TCP"
  protocol_port   = 6443
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_nlb.id
}

resource "openstack_lb_pool_v2" "k8s_api_pool" {
  name        = "k8s-api-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8s_api_listener.id
}

# optional
resource "openstack_lb_monitor_v2" "k8s_api_monitor" {
  name        = "k8s-api-monitor"
  pool_id     = openstack_lb_pool_v2.k8s_api_pool.id
  type        = "TCP"
  delay       = 5
  timeout     = 3
  max_retries = 3
}

resource "openstack_lb_member_v2" "k8s_api_members" {
  count         = 3
  pool_id       = openstack_lb_pool_v2.k8s_api_pool.id
  address       = openstack_compute_instance_v2.master[count.index].access_ip_v4
  protocol_port = 6443
  subnet_id     = openstack_networking_subnet_v2.rke2_subnet.id
}

resource "openstack_lb_listener_v2" "rke2_join_listener" {
  name            = "rke2-join-listener"
  protocol        = "TCP"
  protocol_port   = 9345
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_nlb.id
}

resource "openstack_lb_pool_v2" "rke2_join_pool" {
  name        = "rke2-join-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.rke2_join_listener.id
}

resource "openstack_lb_member_v2" "rke2_join_members" {
  count         = 3
  pool_id       = openstack_lb_pool_v2.rke2_join_pool.id
  address       = openstack_compute_instance_v2.master[count.index].access_ip_v4
  protocol_port = 9345
  subnet_id     = openstack_networking_subnet_v2.rke2_subnet.id
}

resource "openstack_networking_floatingip_v2" "nlb_fip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_networking_floatingip_associate_v2" "nlb_fip_attach" {
  floating_ip = openstack_networking_floatingip_v2.nlb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.k8s_nlb.vip_port_id
}

output "nlb_public_ip" {
  value = openstack_networking_floatingip_v2.nlb_fip.address
}
