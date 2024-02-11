terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vcd-docker-swarm.tfstate"
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
data "vcd_network_direct" "lan_mgmt" {
  name = var.network_name_lan_mgmt
}

//=============================================

resource "vcd_vapp" "dswarm" {
  name        = "Docker Swarm"
  description = "Docker Swarm Cluster"
  power_on    = true
}

resource "vcd_vapp_org_network" "dswarm_lanMgmt" {
  vapp_name              = vcd_vapp.dswarm.name
  org_network_name       = data.vcd_network_direct.lan_mgmt.name
  reboot_vapp_on_removal = true
}

resource "vcd_vapp_org_network" "dswarm_wanInet" {
  vapp_name              = vcd_vapp.dswarm.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

resource "vcd_independent_disk" "dswarm_master" {
  name         = "dswarm-master"
  size_in_mb   = 32 * 1024
  bus_type     = "SCSI"
  bus_sub_type = "VirtualSCSI"
}

locals {
  vms = {
    "master" = {
      disks = [{
        name        = vcd_independent_disk.dswarm_master.name
        bus_number  = 0
        unit_number = 1
      }]
    }
    "node1" = {}
    "node2" = {}
  }
}
module "vms_dswarm" {
  source        = "../../modules/vcd-vapp-vm-ubuntucloud"
  for_each      = local.vms
  vapp_name     = vcd_vapp.dswarm.name
  name          = each.key
  hostname      = each.key
  computer_name = each.key
  cpus          = can(each.value.cpus) ? each.value.cpus : 4
  memory        = (can(each.value.memory) ? each.value.memory : 8) * 1024

  template_disk_size = 64 * 1024
  disks              = lookup(each.value, "disks", [])

  local_admin_password       = var.local_admin_password
  local_admin_authorized_key = var.local_admin_authorized_key
  automation_authorized_key  = var.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.dswarm_wanInet.org_network_name
      is_primary = true
    },
    {
      name       = vcd_vapp_org_network.dswarm_lanMgmt.org_network_name
      is_primary = false
    }
  ]
}

module "post_apply_dswarm" {
  source = "../../modules/post-apply"
  id     = "dswarm"
  vms = {
    for k, bd in module.vms_dswarm : k => bd.data
  }
  networks_config = {
    "${data.vcd_network_direct.lan_mgmt.name}" = {
      if_name : "mgmt"
    }
    "${data.vcd_network_direct.wan_inet.name}" = {
      if_name : "inet"
    }
  }
}

output "name" {
  value = module.post_apply_dswarm.data
}
