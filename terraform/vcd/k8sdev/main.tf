terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.11.0"
    }
  }
  backend "local" {
    path = "../../../.private/tf-states/vcd-k8sdev.tfstate"
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

resource "vcd_vapp" "k8sdev" {
  name        = "KubernetesDev"
  description = "Kubernetes Dev Cluster vApp"
  power_on    = true
}

resource "vcd_vapp_org_network" "k8sdev_wanInet" {
  vapp_name              = vcd_vapp.k8sdev.name
  org_network_name       = data.vcd_network_direct.wan_inet.name
  reboot_vapp_on_removal = true
}

resource "vcd_vapp_org_network" "k8sdev_lanMgmt" {
  vapp_name              = vcd_vapp.k8sdev.name
  org_network_name       = data.vcd_network_direct.lan_mgmt.name
  reboot_vapp_on_removal = true
}

locals {
  vms = {
    "node1" = {
      variables = {
        host_groups = ["kube_control_plane", "kube_node", "etcd"]
      }
    }
    "node2" = {
      variables = {
        host_groups = ["kube_control_plane", "kube_node", "etcd"]
      }
    }
    "node3" = {
      variables = {
        host_groups = ["kube_node", "etcd"]
      }
    }
  }
  vms_list = [for key, val in local.vms : merge({ name = key }, val)]
}

module "vms_k8sdev" {
  source = "../../modules/vcd-vapp-vm-ubuntucloud"
  init   = module.init

  for_each      = local.vms
  vapp_name     = vcd_vapp.k8sdev.name
  name          = each.key
  hostname      = each.key
  computer_name = each.key
  cpus          = can(each.value.cpus) ? each.value.cpus : 4
  memory        = (can(each.value.memory) ? each.value.memory : 8) * 1024

  template_disk_size = 64 * 1024
  disks              = lookup(each.value, "disks", [])

  local_admin_password       = module.init.cloud.local_admin_password
  local_admin_authorized_key = module.init.cloud.local_admin_authorized_key
  automation_authorized_key  = module.init.cloud.automation_authorized_key

  networks = [
    {
      name       = vcd_vapp_org_network.k8sdev_wanInet.org_network_name
      is_primary = true
    },
    {
      name       = vcd_vapp_org_network.k8sdev_lanMgmt.org_network_name
      is_primary = false
    }
  ]
  variables = each.value.variables
}

module "data_state_k8sdev_vms" {
  source = "../../modules/save-data-state"
  init   = module.init
  id     = "k8sdev"
  data = {
    instances = [
      for k, bd in module.vms_k8sdev : bd.data
    ],
    inventory_sections = {
      "calico_rr"               = []
      "k8sdev_cluster:children" = ["kube_control_plane", "kube_node", "calico_rr"]
    }
  }
}
