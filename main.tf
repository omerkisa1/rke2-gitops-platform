terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

provider "openstack" {
  auth_url    = "https://tr-ist-01-apigw.portvmind.com/v3"
  user_name   = var.portvmind_username
  password    = var.portvmind_password
  tenant_id   = var.tenant_id
  domain_name = "Default"
  region      = "tr-ist-01"
}

data "openstack_networking_network_v2" "public_network" {
  network_id = var.external_network_id
}

resource "openstack_networking_floatingip_v2" "master_floatingip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_compute_floatingip_associate_v2" "master_floatingip_attach" {
  floating_ip = openstack_networking_floatingip_v2.master_floatingip.address
  instance_id = openstack_compute_instance_v2.master[0].id
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

resource "openstack_networking_secgroup_v2" "rke2_secgroup" {
  name = "rke2-secgroup"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "rke2_join" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9345
  port_range_max    = 9345
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "kubelet" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "vxlan" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_ip_prefix  = "10.0.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "etcd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_ip_prefix  = "10.0.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "10.0.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
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

resource "openstack_networking_secgroup_rule_v2" "rke2_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rke2_secgroup.id
}

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "rke2-key" {
  name       = "rke2-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "rke2-key"
  file_permission = "0400"
}

resource "openstack_compute_instance_v2" "master" {
  count = 3

  name            = "rke2-master-${count.index + 1}"
  flavor_id       = var.medium_flavor_id
  key_pair        = openstack_compute_keypair_v2.rke2-key.name
  security_groups = [openstack_networking_secgroup_v2.rke2_secgroup.name]

  block_device {
    uuid                  = var.ubuntu_image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 20
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = openstack_networking_network_v2.rke2_network.id
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count = 2

  name            = "rke2-worker-${count.index + 1}"
  flavor_id       = var.micro_flavor_id
  key_pair        = openstack_compute_keypair_v2.rke2-key.name
  security_groups = [openstack_networking_secgroup_v2.rke2_secgroup.name]

  block_device {
    uuid                  = var.ubuntu_image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 20
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = openstack_networking_network_v2.rke2_network.id
  }
}
