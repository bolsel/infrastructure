resource "vcd_vapp" "firewallGw" {
  name        = "FirewallGW"
  description = "Firewall & Gateway"
  power_on    = true
}

resource "vcd_vapp_org_network" "firewallGw_lanMgmt" {
  vapp_name        = vcd_vapp.firewallGw.name
  org_network_name = data.vcd_network_direct.lan_mgmt.name
}

resource "vcd_vapp_org_network" "firewallGw_wanInet" {
  vapp_name        = vcd_vapp.firewallGw.name
  org_network_name = data.vcd_network_direct.wan_inet.name
}

module "vm_zerotrustgw" {
  source = "../modules/vcd-vapp-vm-ubuntucloud"

  vapp_name = vcd_vapp.firewallGw.name
  name      = "zerotrustgw"
  hostname  = "zerotrustgw"
  cpus      = 2

  local_admin_password       = var.local_admin_password
  local_admin_authorized_key = var.local_admin_authorized_key
  automation_authorized_key  = var.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.firewallGw_lanMgmt.org_network_name
      is_primary = false
    },
    {
      name       = vcd_vapp_org_network.firewallGw_wanInet.org_network_name
      is_primary = true
    }
  ]
}

output "vm_zerotrustgw" {
  value = module.vm_zerotrustgw.vms
}