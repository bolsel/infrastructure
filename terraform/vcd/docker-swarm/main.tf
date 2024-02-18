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

//=============================================

module "init" {
  source   = "../../modules/_initialize"
  cloud_id = "vcd"
}

//=============================================

provider "vcd" {
  user                 = module.init.cloud.vcd_user
  password             = module.init.cloud.vcd_pass
  auth_type            = "integrated"
  org                  = module.init.cloud.vcd_org
  vdc                  = module.init.cloud.vcd_vdc
  url                  = module.init.cloud.vcd_url
  max_retry_timeout    = module.init.cloud.vcd_max_retry_timeout
  allow_unverified_ssl = module.init.cloud.vcd_allow_unverified_ssl
}

//=============================================

data "vcd_network_direct" "wan_inet" {
  name = module.init.cloud.network_name_wan_inet
}
data "vcd_network_direct" "lan_mgmt" {
  name = module.init.cloud.network_name_lan_mgmt
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
      variables = {
        host_groups = ["masters"]
      }
    }
    "node1" = {
      variables = {
        host_groups = ["managers"]
      }
    }
    "node2" = {
      variables = {
        host_groups = ["workers"]
      }
    }
  }
}
module "vms_dswarm" {
  source = "../../modules/vcd-vapp-vm-ubuntucloud"
  init   = module.init

  for_each      = local.vms
  vapp_name     = vcd_vapp.dswarm.name
  name          = each.key
  hostname      = each.key
  computer_name = each.key
  cpus          = can(each.value.cpus) ? each.value.cpus : 4
  memory        = (can(each.value.memory) ? each.value.memory : 8) * 1024

  template_disk_size = 64 * 1024
  disks              = lookup(each.value, "disks", [])

  local_admin_password       = module.init.cloud.local_admin_password
  local_admin_authorized_key = module.init.cloud.local_admin_authorized_key
  automation_authorized_key  = module.init.cloud.automation_authorized_key

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
  variables = each.value.variables
}

module "data_state_dswarm" {
  source = "../../modules/save-data-state"
  init   = module.init
  id     = "dswarm"
  data = {
    instances = [
      for k, bd in module.vms_dswarm : merge(bd.data, {
        groupId = "dswarm"
      })
    ]
  }
}
