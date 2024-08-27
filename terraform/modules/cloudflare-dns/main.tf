terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

//=============================================

provider "cloudflare" {
  api_token = var.config.token
}

resource "cloudflare_record" "tunnel_ingress_rules" {
  for_each = var.config.tunnels
  zone_id = var.config.zone_id
  name    = each.key
  type    = each.value.type
  value   = each.value.value
  comment = "automation-dns"
}
