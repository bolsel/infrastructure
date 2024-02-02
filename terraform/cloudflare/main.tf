terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}
provider "cloudflare" {
  api_token = var.cloudflare_token
}

data "cloudflare_tunnel" "main" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
}

locals {
  tunnel_ingress_rules = yamldecode(templatefile("${path.module}/config.yaml", {
    zone = var.cloudflare_zone
  }))
}

resource "cloudflare_tunnel_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = data.cloudflare_tunnel.main.id

  config {
    warp_routing {
      enabled = true
    }
    dynamic "ingress_rule" {
      for_each = local.tunnel_ingress_rules
      content {
        hostname = ingress_rule.key == "@" ? var.cloudflare_zone : "${ingress_rule.key}.${var.cloudflare_zone}"
        service  = ingress_rule.value.service
        dynamic "origin_request" {
          for_each = can(ingress_rule.value.origin_request) ? [ingress_rule.value.origin_request] : []
          content {
            origin_server_name = lookup(origin_request.value, "origin_server_name", null)
            no_tls_verify      = lookup(origin_request.value, "no_tls_verify", null)
            ca_pool            = lookup(origin_request.value, "ca_pool", null)
          }
        }
      }
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "tunnel_ingress_rules" {
  for_each = local.tunnel_ingress_rules

  zone_id = var.cloudflare_zone_id
  name    = each.key
  type    = "CNAME"
  value   = "${data.cloudflare_tunnel.main.id}.cfargotunnel.com"
  proxied = true
  comment = "automation,zerotrust"
}
