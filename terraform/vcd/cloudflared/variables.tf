
variable "vcd_url" {}
variable "vcd_max_retry_timeout" {}
variable "vcd_allow_unverified_ssl" {}
variable "vcd_vdc" {}
variable "vcd_org" {}
variable "vcd_user" {}
variable "vcd_pass" {}

variable "network_name_wan_inet" {
  type = string
}
variable "network_name_lan_mgmt" {
  type = string
}

variable "local_admin_password" {
  type = string
}
variable "local_admin_authorized_key" {
  type = string
}
variable "automation_authorized_key" {
  type = string
}
