resource "vcd_vapp" "dockerswarm" {
  name        = "DockerSwarm"
  description = "DockerSwarm cluster"
  power_on    = true

}

resource "vcd_vapp_org_network" "dockerswarm_lanMgmt" {
  vapp_name              = vcd_vapp.dockerswarm.name
  org_network_name       = data.vcd_network_direct.lan_mgmt.name
  reboot_vapp_on_removal = true
}

resource "vcd_vapp_org_network" "dockerswarm_wanInet" {
  vapp_name              = vcd_vapp.dockerswarm.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

module "vms_dockerswarm" {
  for_each = {
    "dswarm-master" = {
      cpus   = 2
      memory = 2
    }
    "dswarm-node1" = {}
    "dswarm-node2" = {}
  }
  source = "../modules/vcd-vapp-vm-ubuntucloud"

  vapp_name = vcd_vapp.dockerswarm.name
  name      = each.key
  hostname  = each.key
  cpus      = can(each.value.cpus) ? each.value.cpus : 4
  memory    = (can(each.value.memory) ? each.value.memory : 8) * 1024

  local_admin_password       = var.local_admin_password
  local_admin_authorized_key = var.local_admin_authorized_key
  automation_authorized_key  = var.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.dockerswarm_lanMgmt.org_network_name
      is_primary = false
    },
    {
      name       = vcd_vapp_org_network.dockerswarm_wanInet.org_network_name
      is_primary = true
    }
  ]
}

module "networks_config_file_dockerswarm" {
  source          = "../modules/networks-config-file"
  for_each        = module.vms_dockerswarm
  networks_config = local.network_config
  vm              = each.value.data_vm
}

output "vms_dockerswarm" {
  value = {
    for k, bd in module.vms_dockerswarm : k => bd.data
  }
}
