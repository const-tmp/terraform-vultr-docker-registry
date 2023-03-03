data "vultr_dns_domain" "domain" {
  domain = var.domain
}

locals {
  nginx_config = templatefile("${path.root}/configs/registry.conf", {
    server_name = "${var.subdomain}.${var.domain}"
  })

  cloud_init = templatefile("${path.root}/scripts/cloud-init.sh", {
    nginx_config               = local.nginx_config
    domain                     = var.domain
    subdomain                  = var.subdomain
    linux_user                 = var.linux_user
    linux_user_hashed_password = var.linux_user_hashed_password
    registry_auth              = var.registry_auth
  })
}

module "vms" {
  source  = "nullc4t/ec2/vultr"
  version = ">= 0.0.2"

  region       = var.region
  ssh_key_name = var.ssh_key_name
  os_id        = var.os_id
  snapshot_id  = null
  vpc_ids      = []
  vm_instances = {
    registry = {
      plan           = var.plan
      count          = 1
      startup_script = local.cloud_init
    }
  }
}

resource "vultr_dns_record" "dns" {
  data   = module.vms.instances["registry"]["registry-0"].public_ip
  domain = data.vultr_dns_domain.domain.domain
  name   = var.subdomain
  type   = "A"
}
