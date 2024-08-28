terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.8.2"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vsphere-local/k8s-generic-cluster.tfstate"
  }
}

module "vsphere_local_vars" {
  source = "../../modules/get-vars"
  name   = "vsphere-local/config"
}

provider "vsphere" {
  user                 = module.vsphere_local_vars._.user
  password             = module.vsphere_local_vars._.password
  vsphere_server       = module.vsphere_local_vars._.vsphere_server
  allow_unverified_ssl = module.vsphere_local_vars._.allow_unverified_ssl
  api_timeout          = module.vsphere_local_vars._.api_timeout
}
data "vsphere_datacenter" "datacenter" {
  name = module.vsphere_local_vars._.datacenter_name
}
data "vsphere_datastore" "datastore" {
  name          = module.vsphere_local_vars._.datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
data "vsphere_host" "host" {
  name          = module.vsphere_local_vars._.host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = module.vsphere_local_vars._.network_k8s_generic
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_content_library" "templates" {
  name = "templates"
}
data "vsphere_content_library_item" "clitem" {
  name       = module.vsphere_local_vars._.template_name_k8s_generic
  type       = "ovf"
  library_id = data.vsphere_content_library.templates.id
}
locals {
  vms = {
    "node1" = {
      cpu    = 2
      memory = 1024 * 4
    }
    "node2" = {
      cpu    = 2
      memory = 1024 * 4
    }
    "node3" = {
      cpu    = 2
      memory = 1024 * 4
    }
    "node4" = {
      cpu    = 4
      memory = 1024 * 8
    }
    "node5" = {
      cpu    = 4
      memory = 1024 * 8
    }
  }
}

resource "vsphere_vapp_container" "vapp" {
  name                    = "k8slocal-generic-cluster"
  parent_resource_pool_id = data.vsphere_host.host.resource_pool_id
}
resource "vsphere_virtual_machine" "vms" {
  for_each         = local.vms
  name             = lower(join("-", [vsphere_vapp_container.vapp.name, each.key]))
  resource_pool_id = vsphere_vapp_container.vapp.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = each.value.cpu
  memory           = each.value.memory
  clone {
    template_uuid = data.vsphere_content_library_item.clitem.id
  }
  vapp {
    properties = {
      instance-id = lower(join("-", ["k8slocal-generic", each.key]))
      hostname    = lower(join("-", ["k8slocal-generic", each.key]))
      user-data = base64encode(templatefile("${path.module}/userdata.yaml", {
        hostname                   = lower(join("-", ["k8slocal-generic", each.key]))
        local_admin_username       = module.vsphere_local_vars._.local_admin_username
        local_admin_password       = module.vsphere_local_vars._.local_admin_password
        local_admin_authorized_key = module.vsphere_local_vars._.local_admin_authorized_key
      }))
    }
  }
  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/userdata.yaml", {
      hostname                   = each.key
      local_admin_username       = module.vsphere_local_vars._.local_admin_username
      local_admin_password       = module.vsphere_local_vars._.local_admin_password
      local_admin_authorized_key = module.vsphere_local_vars._.local_admin_authorized_key
    }))
    "guestinfo.userdata.encoding" = "base64"
    "disk.EnableUUID"             = "TRUE"
  }
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 64
  }

  cdrom {
    client_device = true
  }
}
