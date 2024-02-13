locals {
  private_dir = "${path.module}/../../../.private"
  cloud       = yamldecode(file("${local.private_dir}/variables/cloud-config/${var.cloud_id}.yml"))
}

output "cloud_id" {
  value = var.cloud_id
}

output "cloud" {
  value = local.cloud
}
