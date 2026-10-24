#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

echo ">> Creating Users."

useradd -r -s /bin/false -U factorio
usermod -aG factorio factorio

rm -rf factorio
curl -LJo linux64.tar.xz https://factorio.com/get-download/stable/headless/linux-arm64
tar -xvf linux64.tar.xz

echo ">> Installing Files"
mkdir -p /opt/factorio
rsync -azP factorio /opt/factorio

mkdir -p /opt/factorio/factorio/saves
chown -R factorio:factorio /opt/factorio/factorio

echo ">> Creating service file."

cat << 'EOF' >| /etc/systemd/system/factorio.service
[Unit]
Description=Factorio
After=network.target network-online.target bluetooth.service tailscaled.service multi-user.target
Wants=network.target network-online.target bluetooth.service tailscaled.service multi-user.target

[Service]
Type=exec
WorkingDirectory=/opt/factorio
User=factorio
Group=factorio
Restart=always
RestartSec=5

# Clean up any leftover stopped container before launching a new one
ExecStartPre=-docker stop factorio-server
ExecStartPre=-docker rm factorio-server

ExecStart=docker run -i --name factorio-server -v /opt/factorio:/opt/factorio -p 34197:34197/udp rockylinux/rockylinux:10 /opt/factorio/factorio/bin/arm64/factorio --use-server-whitelist --server-whitelist /opt/factorio/server-whitelist.json --server-adminlist /opt/factorio/server-adminlist.json --use-authserver-bans --server-settings /opt/factorio/server-settings.json --start-server-load-latest

ExecStop=/usr/bin/docker stop factorio-server

[Install]
WantedBy=multi-user.target
EOF

echo ">> Starting service."

systemctl daemon-reload
systemctl enable factorio.service
systemctl restart factorio.service
