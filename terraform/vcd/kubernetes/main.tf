terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vcd-kubernetes.tfstate"
  }
}

provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_pass
  auth_type            = "integrated"
  org                  = var.vcd_org
  vdc                  = var.vcd_vdc
  url                  = var.vcd_url
  max_retry_timeout    = var.vcd_max_retry_timeout
  allow_unverified_ssl = var.vcd_allow_unverified_ssl
}

//=============================================

data "vcd_network_direct" "wan_inet" {
  name = var.network_name_wan_inet
}

//=============================================

resource "vcd_vapp" "k8s" {
  name        = "Kubernetes"
  description = "Kubernetes Cluster vApp"
  power_on    = true
}

resource "vcd_vapp_org_network" "k8s_wanInet" {
  vapp_name              = vcd_vapp.k8s.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

locals {
  vms = {
    "node1" = {}
    "node2" = {}
    "node3" = {}
  }
  vms_list = [for key, val in local.vms : merge({ name = key }, val)]
}

module "vms_k8s" {
  source        = "../../modules/vcd-vapp-vm-ubuntucloud"
  for_each      = local.vms
  vapp_name     = vcd_vapp.k8s.name
  name          = each.key
  hostname      = each.key
  computer_name = each.key
  cpus          = can(each.value.cpus) ? each.value.cpus : 8
  memory        = (can(each.value.memory) ? each.value.memory : 16) * 1024

  template_disk_size = 64 * 1024
  disks              = lookup(each.value, "disks", [])

  local_admin_password       = var.local_admin_password
  local_admin_authorized_key = var.local_admin_authorized_key
  automation_authorized_key  = var.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.k8s_wanInet.org_network_name
      is_primary = true
    }
  ]
}

module "post_apply_k8s" {
  source = "../../modules/post-apply"
  id     = "dswarm"
  vms = {
    for k, bd in module.vms_k8s : k => bd.data
  }
  networks_config = {
    "${data.vcd_network_direct.wan_inet.name}" = {
      if_name : "inet"
    }
  }
}

output "name" {
  value = module.post_apply_k8s.data
}
