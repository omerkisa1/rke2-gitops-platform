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
