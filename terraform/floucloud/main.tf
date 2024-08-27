terraform {
  backend "local" {
    path = "../../.private/tf-states/floucloud/cloudflared-tunnel.tfstate"
  }
}

//=============================================

module "vars_tunnel" {
  source   = "../modules/get-vars"
  name = "cloudflared/floucloud-tunnel"
}
module "vars_dns" {
  source   = "../modules/get-vars"
  name = "cloudflared/floucloud-dns"
}
module "cloudflared_tunnel" {
  source   = "../modules/cloudflared-tunnel"
  config = module.vars_tunnel._
}
module "cloudflare_dns" {
  source   = "../modules/cloudflare-dns"
  config = module.vars_dns._
}
