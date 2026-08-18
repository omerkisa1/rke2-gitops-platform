resource "openstack_lb_loadbalancer_v2" "k8s_alb" {
  name          = "rke2-alb"
  vip_subnet_id = openstack_networking_subnet_v2.rke2_subnet.id

}

resource "openstack_lb_listener_v2" "http_listener" {
  name            = "http-listener"
  protocol        = "TCP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_alb.id
}

resource "openstack_lb_pool_v2" "http_pool" {
  name        = "http-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.http_listener.id
}

resource "openstack_lb_monitor_v2" "http_monitor" {
  name        = "http-monitor"
  pool_id     = openstack_lb_pool_v2.http_pool.id
  type        = "TCP"
  delay       = 5
  timeout     = 3
  max_retries = 3
}

resource "openstack_lb_member_v2" "http_members" {
  count         = 2
  pool_id       = openstack_lb_pool_v2.http_pool.id
  address       = openstack_compute_instance_v2.worker[count.index].access_ip_v4
  protocol_port = 80
  subnet_id     = openstack_networking_subnet_v2.rke2_subnet.id
}

resource "openstack_lb_listener_v2" "https_listener" {
  name            = "https-listener"
  protocol        = "TCP"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_alb.id
}

resource "openstack_lb_pool_v2" "https_pool" {
  name        = "https-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.https_listener.id
}

resource "openstack_lb_member_v2" "https_members" {
  count         = 2
  pool_id       = openstack_lb_pool_v2.https_pool.id
  address       = openstack_compute_instance_v2.worker[count.index].access_ip_v4
  protocol_port = 443
  subnet_id     = openstack_networking_subnet_v2.rke2_subnet.id
}

resource "openstack_networking_floatingip_v2" "alb_fip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_networking_floatingip_associate_v2" "alb_fip_attach" {
  floating_ip = openstack_networking_floatingip_v2.alb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.k8s_alb.vip_port_id
}

output "alb_public_ip" {
  value = openstack_networking_floatingip_v2.alb_fip.address
}
