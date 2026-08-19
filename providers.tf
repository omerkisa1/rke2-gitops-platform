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
