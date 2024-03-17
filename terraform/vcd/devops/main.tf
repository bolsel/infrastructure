terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vcd-devops.tfstate"
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

resource "vcd_vapp" "devops" {
  name        = "Devops"
  description = "Devops vApp"
  power_on    = true
}

resource "vcd_vapp_org_network" "devops_wanInet" {
  vapp_name              = vcd_vapp.devops.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

resource "vcd_vapp_org_network" "devops_lanMgmt" {
  vapp_name              = vcd_vapp.devops.name
  org_network_name       = data.vcd_network_direct.lan_mgmt.name
  reboot_vapp_on_removal = true
}

locals {
  vms = {
    "gitlab" = {
      cpus               = 4
      memory             = 6
      template_disk_size = 45
    }
    # "gitlab-runner1" = {
    #   cpus   = 4
    #   memory = 6
    # }
  }
  vms_list = [for key, val in local.vms : merge({ name = key }, val)]
}

module "vms_devops" {
  source        = "../../modules/vcd-vapp-vm-ubuntucloud"
  init          = module.init
  template_name = "Ubuntu 22.04 Server (20240223)"

  for_each      = local.vms
  vapp_name     = vcd_vapp.devops.name
  name          = each.key
  hostname      = each.key
  computer_name = each.key
  cpus          = can(each.value.cpus) ? each.value.cpus : 3
  memory        = (can(each.value.memory) ? each.value.memory : 4) * 1024

  template_disk_size = (can(each.value.template_disk_size) ? each.value.template_disk_size : 32) * 1024
  disks              = lookup(each.value, "disks", [])

  local_admin_password       = module.init.cloud.local_admin_password
  local_admin_authorized_key = module.init.cloud.local_admin_authorized_key
  automation_authorized_key  = module.init.cloud.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.devops_wanInet.org_network_name
      is_primary = true
    },
    {
      name       = vcd_vapp_org_network.devops_lanMgmt.org_network_name
      is_primary = false
    }
  ]
  # variables = each.value.variables
}

module "data_state_devops_vms" {
  source = "../../modules/save-data-state"
  init   = module.init
  id     = "devops"
  data = {
    instances = [
      for k, bd in module.vms_devops : bd.data
    ],
    # inventory_sections = {
    #   "calico_rr"            = []
    #   "k8s_cluster:children" = ["kube_control_plane", "kube_node", "calico_rr"]
    # }
  }
}
