locals {
  private_dir = "${path.module}/../../../.private"
  cloud       = yamldecode(file("${local.private_dir}/variables/cloud-config/${var.cloud_id}.yml"))
  cloudflared = merge(yamldecode(file("${local.private_dir}/cloudflared/variables.yml")), {
    cloudflared_tunnels_file = "${local.private_dir}/cloudflared/tunnels.yml"
  })
}

output "cloud_id" {
  value = var.cloud_id
}

output "cloud" {
  value = local.cloud
}

output "cloudflared" {
  value = local.cloudflared
}
