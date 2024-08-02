locals {
  private_dir = "${path.module}/../../../.private"
  variables   = yamldecode(file("${local.private_dir}/variables/${var.name}.yml"))
}

output "_" {
  value       = local.variables
  description = "Variables value"
}
