terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}

locals {
  data_states_dir = "${path.module}/../../../.private/data-states"
}

resource "local_file" "save_data" {
  content  = yamlencode(var.data)
  filename = "${local.data_states_dir}/${var.init.cloud_id}/${var.key}/${var.id}.yaml"
}
