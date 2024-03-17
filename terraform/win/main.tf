terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
}

module "init" {
  source   = "../modules/_initialize"
  cloud_id = "vcd"
}

data "vcd_catalog" "name" {
  name = "bolsel"
}
data "vcd_catalog_vapp_template" "win" {
  catalog_id = data.vcd_catalog.name.id
  name       = "windows-server-2022-datacenter"
}
resource "vcd_vm" "name" {
  name             = "wintes"
  vapp_template_id = data.vcd_catalog_vapp_template.win.id
  computer_name    = "wintes"
  customization {
    enabled                    = true
    allow_local_admin_password = true
    admin_password             = "password"
  }

}
output "name" {
  value = data.vcd_catalog_vapp_template.win.id
}
