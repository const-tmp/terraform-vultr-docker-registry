data "vultr_ssh_key" "ssh_key" {
  filter {
    name   = "name"
    values = ["ecdsa"]
  }
}

data "vultr_dns_domain" "domain" {
  domain = var.domain
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
      plan           = "vc2-1c-1gb"
      count          = 1
      startup_script = <<EOF
#!/usr/bin/env bash

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

export DEBIAN_FRONTEND=noninteractive
apt-get install -y nginx ufw certbot python3-certbot-nginx

rm /etc/nginx/sites-enabled/default

cat <<EOT > /etc/nginx/conf.d/registry.conf
server {
	listen 80;

	server_name ${var.subdomain}.${var.domain};

	location / {
        proxy_pass http://127.0.0.1:5000;
	}
}
EOT

service nginx restart

sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
ufw disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 'Nginx Full'
ufw allow 'OpenSSH'
ufw --force enable

certbot --nginx -d ${var.subdomain}.${var.domain} --agree-tos -m admin@${var.domain} -n

crontab -l > mycron
echo '30 2 1 * * certbot renew' >> mycron
crontab mycron
rm mycron

useradd -m -p ${var.user_hashed_password} -g docker registry

sudo -u registry mkdir -p /home/registry/auth
sudo -u registry echo ${var.registry_auth} > /home/registry/auth/htpasswd

sudo -u registry docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /home/registry/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2
EOF
    }
  }
}

resource "vultr_dns_record" "dns" {
  data   = module.vms.instances["registry"]["registry-0"].public_ip
  domain = data.vultr_dns_domain.domain.domain
  name   = var.subdomain
  type   = "A"
}

#-v "$(pwd)"/certs:/certs \
#-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
#-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
