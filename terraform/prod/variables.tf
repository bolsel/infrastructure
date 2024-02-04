
variable "vcd_url" {}
variable "vcd_max_retry_timeout" {}
variable "vcd_allow_unverified_ssl" {}
variable "vcd_vdc" {}
variable "vcd_org" {}
variable "vcd_user" {}
variable "vcd_pass" {}

variable "vcd_nsxt_edgegateway_name" {}
variable "network_name_wan_inet" {}
variable "network_name_ad_bolselkab_goid" {
  default = "ad.bolselkab.go.id"
}
variable "network_name_bolsel_gov" {
  default = "bolsel.gov"
}
variable "network_name_lan_mgmt" {
  default = "net_routed"
}

variable "local_admin_password" {}
variable "local_admin_authorized_key" {}
variable "automation_authorized_key" {}
