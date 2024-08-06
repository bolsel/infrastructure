terraform {
  backend "local" {
    path = "../../.private/tf-states/floucloud/cloudflared-tunnel.tfstate"
  }
}

//=============================================

module "vars" {
  source   = "../modules/get-vars"
  name = "cloudflared/floucloud-tunnel"
}
module "cloudflared_tunnel" {
  source   = "../modules/cloudflared-tunnel"
  config = module.vars._
}
