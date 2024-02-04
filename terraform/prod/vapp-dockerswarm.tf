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

resource "vcd_independent_disk" "dockerswarm_disk_master" {
  name         = "dockerswarm_disk_master"
  size_in_mb   = 32 * 1024
  bus_type     = "SCSI"
  bus_sub_type = "VirtualSCSI"

}

module "vms_dockerswarm" {
  source = "../modules/vcd-vapp-vm-ubuntucloud"
  for_each = {
    "dswarm-master" = {
      disks = [{
        name        = vcd_independent_disk.dockerswarm_disk_master.name
        bus_number  = 0
        unit_number = 1
      }]
    }
    "dswarm-node1" = {}
    "dswarm-node2" = {}
    "dswarm-node3" = {}
    "dswarm-node4" = {}
  }

  vapp_name     = vcd_vapp.dockerswarm.name
  name          = replace(each.key, "dswarm-", "")
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
      name       = vcd_vapp_org_network.dockerswarm_wanInet.org_network_name
      is_primary = true
    },
    {
      name       = vcd_vapp_org_network.dockerswarm_lanMgmt.org_network_name
      is_primary = false
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
