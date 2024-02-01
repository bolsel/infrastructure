
# NETWORKS ==================
data "vcd_nsxt_edgegateway" "ORG_NSX_VDC" {
  name = var.vcd_nsxt_edgegateway_name
}

data "vcd_network_direct" "wan_inet" {
  name = var.network_name_wan_inet
}

data "vcd_network_direct" "ad_bolselkab_goid" {
  name = var.network_name_ad_bolselkab_goid
}

data "vcd_network_direct" "bolsel_gov" {
  name = var.network_name_bolsel_gov
}

data "vcd_network_direct" "lan_mgmt" {
  name = var.network_name_lan_mgmt
}

# ============================

locals {
  network_config = {
    "${data.vcd_network_direct.lan_mgmt.name}" = {
      if_name : "mgmt"
    }
    "${data.vcd_network_direct.wan_inet.name}" = {
      if_name : "inet"
    }
  }
}
