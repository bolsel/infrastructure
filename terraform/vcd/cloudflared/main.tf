terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vcd-cloudflared.tfstate"
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
  init     = module.init

  vapp_name = vcd_vapp.cloudflared.name
  name      = each.value
  hostname  = each.value
  cpus      = 2

  local_admin_password       = module.init.cloud.local_admin_password
  local_admin_authorized_key = module.init.cloud.local_admin_authorized_key
  automation_authorized_key  = module.init.cloud.automation_authorized_key

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

module "data_state_cloudflared" {
  source = "../../modules/save-data-state"
  init   = module.init
  key    = "vms"
  id     = "cloudflared"
  data = {
    cloudflared = [
      for k, bd in module.vms_cloudflared : merge(bd.data, {
        groupId = "cloudflared"
      })
    ]
  }
}
