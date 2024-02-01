terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
}

data "vcd_catalog" "catalog" {
  name = var.catalog_name
}

data "vcd_catalog_vapp_template" "template" {
  catalog_id = data.vcd_catalog.catalog.id
  name       = var.template_name
}

locals {
  hostname      = var.hostname != "" ? var.hostname : var.name
  computer_name = var.computer_name != "" ? var.computer_name : local.hostname
}

resource "vcd_vapp_vm" "vm" {
  name                      = var.name
  description               = var.description
  vapp_name                 = var.vapp_name
  vapp_template_id          = data.vcd_catalog_vapp_template.template.id
  computer_name             = local.computer_name
  memory                    = var.memory
  cpus                      = var.cpus
  firmware                  = var.firmware
  hardware_version          = var.hardware_version
  power_on                  = true
  network_dhcp_wait_seconds = 60

  dynamic "override_template_disk" {
    for_each = var.template_disk_size != 0 ? [var.template_disk_size] : []
    content {
      bus_type    = "paravirtual"
      size_in_mb  = override_template_disk.value
      bus_number  = 0
      unit_number = 0
    }
  }

  dynamic "network" {
    for_each = var.networks

    content {
      type               = network.value.type
      adapter_type       = network.value.adapter_type
      name               = network.value.name
      ip_allocation_mode = network.value.ip_allocation_mode
      ip                 = network.value.ip
      is_primary         = network.value.is_primary
    }
  }

  guest_properties = {
    "instance-id" = lower(join("-", [var.vapp_name, local.hostname]))
    "hostname"    = local.hostname
    "user-data" = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      hostname                   = local.hostname
      local_admin_username       = var.local_admin_username
      automation_username        = var.automation_username
      local_admin_password       = var.local_admin_password
      local_admin_authorized_key = var.local_admin_authorized_key
      automation_authorized_key  = var.automation_authorized_key
    }))
  }
}

output "data_vm" {
  value = vcd_vapp_vm.vm
}

output "data" {
  value = {
    name     = vcd_vapp_vm.vm.name
    hostname = local.hostname
    networks = [
      for index, net in vcd_vapp_vm.vm.network : {
        name   = net.name
        ip     = net.ip
        mac    = net.mac
        macrep = replace(net.mac, ":", "")
      }
    ],
  }
}
