terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
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
  source   = "../../modules/vcd-vapp-vm-ubuntucloud"

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

module "post_apply_cloudflared" {
  source = "../../modules/post-apply"
  id     = "cloudflared"
  vms = {
    for k, bd in module.vms_cloudflared : k => bd.data
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

output "vms_cloudflared" {
  value = module.post_apply_cloudflared.data
}
