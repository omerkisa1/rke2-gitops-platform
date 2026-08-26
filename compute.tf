resource "openstack_networking_floatingip_v2" "master_floatingip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_compute_floatingip_associate_v2" "master_floatingip_attach" {
  floating_ip = openstack_networking_floatingip_v2.master_floatingip.address
  instance_id = openstack_compute_instance_v2.master[0].id
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


output "master1_public_ip" {
  value = openstack_networking_floatingip_v2.master_floatingip.address
}
