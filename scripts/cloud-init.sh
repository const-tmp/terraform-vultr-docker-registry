#!/usr/bin/env bash

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

export DEBIAN_FRONTEND=noninteractive
apt-get install -y nginx ufw certbot python3-certbot-nginx

rm /etc/nginx/sites-enabled/default

cat <<EOT > /etc/nginx/conf.d/registry.conf
${nginx_config}
EOT

service nginx restart

sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
ufw disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 'Nginx Full'
ufw allow 'OpenSSH'
ufw --force enable

certbot --nginx -d ${subdomain}.${domain} --agree-tos -m admin@${domain} -n

crontab -l > mycron
echo '30 2 1 * * certbot renew' >> mycron
crontab mycron
rm mycron

useradd -m -p '${linux_user_hashed_password}' -g docker -s /bin/bash ${linux_user}

sudo -u ${linux_user} mkdir -p /home/${linux_user}/auth
sudo -u ${linux_user} echo '${registry_auth}' > /home/${linux_user}/auth/htpasswd
chown -R ${linux_user}:${linux_user} /home/${linux_user}/auth

sudo -u ${linux_user} docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /home/${linux_user}/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2
