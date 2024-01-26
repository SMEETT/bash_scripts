#!/bin/bash
# VARS
caddy_email="tbr@tutamail.com"
caddy_subdomain='https://gh.gehtbeidir.de'
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

# remove apache!! TODO

# install NVM & Node
# yes Y | curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
# source ~/.nvm/nvm.sh
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# yes Y | nvm install 16.17.0
# source ~/.nvm/nvm.sh
# set prefix so we install pm2 into /usr/local/bin
# npm config set prefix /usr/local
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# PM2
yes | npm i pm2 -g
# reset the npm-prefix to what it was before
# nvm use --delete-prefix v16.17.0 --silent
# source ~/.nvm/nvm.sh

adduser --disabled-password --gecos "" pm2node
mkdir -p /var/pm2node/pm2daemon
chown -R pm2node /var/pm2node
chmod -R 770 /var/pm2node
echo "PM2_HOME=/var/pm2node/pm2daemon" >> /etc/environment

cat > /etc/systemd/system/pm2-node.service <<EOF
[Unit]
Description=PM2 Process Manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=pm2node
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
Environment=PM2_HOME=/var/pm2node/pm2daemon
PIDFile=/var/pm2node/pm2daemon/pm2.pid
ReadWritePaths=/var/pm2node/ /var/pm2node/pm2daemon
Restart=on-failure
ProtectHome=true
ProtectSystem=strict
PrivateTmp=true

ExecStart=/usr/bin/pm2 resurrect
ExecReload=/usr/bin/pm2 reload all
ExecStop=/usr/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start pm2-node
systemctl enable pm2-node

echo "thisthis" #safety first

# GitHub Actions SSH
yes ~/.ssh/id_ghactions | ssh-keygen -q -t rsa -b 4096 -C "$gh_email" -N '' >/dev/null
cat ~/.ssh/id_ghactions.pub >> ~/.ssh/authorized_keys
mv ~/.ssh /home/pm2node/
chown -R pm2node /home/pm2node/.ssh 
cat /home/pm2node/.ssh/id_ghactions
