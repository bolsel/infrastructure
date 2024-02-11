terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}

locals {
  path = var.path != "" ? "${var.path}/${var.vm.computer_name}" : "${var.vm.computer_name}"
}
resource "local_file" "networks_config_file" {
  content = templatefile("${path.module}/netplan.yaml.tpl", {
    networks_config = var.networks_config
    vm              = var.vm
  })
  filename = "${path.module}/../../../private/netplan-config/${local.path}/10-default.yaml"
}
