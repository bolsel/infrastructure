locals {
  content = {
    network = {
      version = 2
      ethernets = {
        for v in var.vm.network : var.networks_config[v.name].if_name =>
        {
          dhcp4           = true
          dhcp-identifier = "mac"
          match = {
            macaddress = v.mac
          }
          "set-name" = var.networks_config[v.name].if_name
        }
      }
    }
  }
}
resource "local_file" "networks_config_file" {
  content  = replace(yamlencode(local.content), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
  filename = "${path.root}/../../private/netplan-config/${var.vm.computer_name}/10-default.yaml"
}
