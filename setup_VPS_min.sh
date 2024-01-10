#!/bin/bash
# VARS
caddy_email="tbr@tutamail.com"
caddy_subdomain='https://test.definite-yoga.koeln'
gh_email="tbr@tutamail.com"

set -e
echo "#######################################"
echo "ABOUT TO BASH 'EM ALL!!"
echo "#######################################"

echo "#######################################"
echo "general updates && HTOP install && Build Essentials"
echo "#######################################"
# general updates && HTOP install
apt update && apt upgrade
apt install htop
apt-get install build-essential

echo "#######################################"
echo "set NODE_ENV"
echo "#######################################"
echo "NODE_ENV=production" >> /etc/environment

echo "#######################################"
echo "set-up automatic upgrades"
echo "#######################################"
# automatic upgrades
apt install unattended-upgrades
yes | dpkg-reconfigure --priority=low unattended-upgrades

echo "#######################################"
echo "install Caddy"
echo "#######################################"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https &&
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg &&
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list &&
sudo apt update &&
sudo apt install caddy

# Fileserver with TLS (for testing)
mkdir -p /var/caddy/fileserver
touch /var/caddy/fileserver/test.file

cat > /etc/caddy/Caddyfile <<EOF
{
        email $caddy_email
}

$caddy_subdomain {
        encode gzip
				root * /var/caddy/fileserver
        log {
                output file /var/log/caddy/fileserver_access.log
        }
}
EOF

# format Caddy-File
caddy fmt --overwrite /etc/caddy/Caddyfile

# set-up Caddy working-dir's
mkdir -p /etc/caddy/.config /etc/caddy/.local /var/log/caddy /var/caddy &&
chown -R caddy: /etc/caddy /var/log/caddy /var/caddy &&
setcap cap_net_bind_service+ep /usr/bin/caddy

cat > /etc/systemd/system/caddy.service <<EOF
[Unit]
Description=Caddy Web Server
After=network-online.target

[Service]
User=caddy
Group=caddy
Type=exec
WorkingDirectory=/var/caddy

ExecStart=/usr/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
ExecStop=/usr/bin/caddy stop

LimitNOFILE=1048576
LimitNPROC=512

PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/etc/caddy/.local /etc/caddy/.config /var/log /var/lib/caddy

CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl start caddy
systemctl restart caddy
systemctl enable caddy

# install GIT
apt-get update
yes Y | apt-get install git

echo "thisthis" #safety first
