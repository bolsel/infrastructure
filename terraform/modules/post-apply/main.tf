terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}

locals {
  saved_vms_dir = "${path.module}/../../../.private/saved-vms"
  inventory_dir = "${path.module}/../../../.private/inventory"
  netplan_dir   = "${path.module}/../../../.private/netplan"
}

resource "local_file" "save_vms" {
  content  = yamlencode({ "${var.id}" = var.vms })
  filename = "${local.saved_vms_dir}/${var.id}.yaml"
}
locals {
  all_vms_concat = join("\n", [
    for fn in fileset(local.saved_vms_dir, "*.yaml") : file("${local.saved_vms_dir}/${fn}")
  ])
  all_vms = local.all_vms_concat != "" ? yamldecode(local.all_vms_concat) : {}
}

resource "local_file" "netplan_config" {
  for_each = var.vms
  content = templatefile("${path.module}/templates/netplan.yaml.tpl", {
    networks_config = var.networks_config
    vm              = each.value
  })
  filename = "${local.netplan_dir}/${var.id}/${each.value.hostname}/10-default.yaml"
}

resource "local_file" "ansible_inventory_all" {
  content = templatefile("${path.module}/templates/ansible-inventory-all.ini.tpl", {
    data = local.all_vms
  })
  filename = "${local.inventory_dir}/hosts.ini"
}
resource "local_file" "ansible_inventory_group" {
  content = templatefile("${path.module}/templates/ansible-inventory-group.ini.tpl", {
    data = var.vms
  })
  filename = "${local.inventory_dir}/${var.id}.ini"
}


output "data" {
  value = var.vms
}
