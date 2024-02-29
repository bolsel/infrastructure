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

resource "vcd_vapp_network" "k8sdev_advertise" {
  vapp_name     = vcd_vapp.k8sdev.name
  name          = "advertise2"
  gateway       = "192.168.10.1"
  prefix_length = "27"
  static_ip_pool {
    start_address = "192.168.10.2"
    end_address   = "192.168.10.29"
  }
  reboot_vapp_on_removal = true
}

locals {
  vms = {
    "master" = {
      advertise_end_ip = 1
      variables = {
        host_groups = ["mk8s_master", "kube_control_plane", "kube_node", "etcd"]
      }
    }
    "node-01" = {
      advertise_end_ip = 2
      variables = {
        host_groups = ["mk8s_control_plane", "kube_control_plane", "kube_node", "etcd"]
      }
    }
    "node-02" = {
      advertise_end_ip = 3
      variables = {
        host_groups = ["mk8s_control_plane", "kube_control_plane", "kube_node", "etcd"]
      }
    }
    "node-03" = {
      advertise_end_ip = 4
      variables = {
        host_groups = ["mk8s_worker", "kube_node", "etcd"]
      }
    }
    "node-04" = {
      advertise_end_ip = 5
      variables = {
        host_groups = ["mk8s_worker", "kube_node", "etcd"]
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
  cpus          = can(each.value.cpus) ? each.value.cpus : 2
  memory        = (can(each.value.memory) ? each.value.memory : 4) * 1024

  template_disk_size = 32 * 1024
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
    },
    {
      type               = "vapp"
      name               = vcd_vapp_network.k8sdev_advertise.name
      is_primary         = false
      ip_allocation_mode = "MANUAL"
      ip                 = "192.168.10.1${each.value.advertise_end_ip}"
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
      "calico_rr"            = []
      "k8s_cluster:children" = ["kube_control_plane", "kube_node", "calico_rr"]
    }
  }
}
