resource "vcd_vapp" "cloudflared" {
  name        = "cloudflared"
  description = "cloudflare zerotrust gateway"
  power_on    = true

}

resource "vcd_vapp_org_network" "cloudflared_lanMgmt" {
  vapp_name              = vcd_vapp.cloudflared.name
  org_network_name       = data.vcd_network_direct.lan_mgmt.name
  reboot_vapp_on_removal = true
}

resource "vcd_vapp_org_network" "cloudflared_wanInet" {
  vapp_name              = vcd_vapp.cloudflared.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

module "vms_cloudflared" {
  for_each = toset(["cloudflared1", "cloudflared2"])
  source   = "../modules/vcd-vapp-vm-ubuntucloud"

  vapp_name = vcd_vapp.cloudflared.name
  name      = each.value
  hostname  = each.value
  cpus      = 2

  local_admin_password       = var.local_admin_password
  local_admin_authorized_key = var.local_admin_authorized_key
  automation_authorized_key  = var.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.cloudflared_lanMgmt.org_network_name
      is_primary = false
    },
    {
      name       = vcd_vapp_org_network.cloudflared_wanInet.org_network_name
      is_primary = true
    }
  ]
}

output "vms_cloudflared" {
  value = {
    for k, bd in module.vms_cloudflared : k => bd
  }
}