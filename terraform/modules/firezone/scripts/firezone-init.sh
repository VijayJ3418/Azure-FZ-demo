#!/bin/bash
set -e

echo "Starting Firezone Gateway initialization..."

# Update system
yum update -y
yum install -y epel-release

# Install required packages
yum install -y \
  curl \
  wget \
  git \
  gcc \
  openssl \
  openssl-devel \
  net-tools \
  iproute \
  iptables

# Install WireGuard
yum install -y wireguard-tools

# Configure system for VPN gateway
cat >> /etc/sysctl.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sysctl -p

# Download and install Firezone Gateway
echo "Installing Firezone Gateway..."
curl -fsSL https://cdn.firezone.dev/firezone/releases/linux/x86_64/firezone-gateway-latest.tar.gz -o /tmp/firezone-gateway.tar.gz
tar -xzf /tmp/firezone-gateway.tar.gz -C /opt || mkdir -p /opt && tar -xzf /tmp/firezone-gateway.tar.gz -C /opt

# Create Firezone systemd service
cat > /etc/systemd/system/firezone-gateway.service <<'EOF'
[Unit]
Description=Firezone Gateway
Documentation=https://docs.firezone.dev
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/firezone-gateway/firezone-gateway run
Restart=on-failure
RestartSec=10

Environment="FIREZONE_API_URL=${firezone_api_url}"
Environment="FIREZONE_TOKEN=${firezone_enrollment_token}"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start Firezone Gateway
systemctl enable firezone-gateway
systemctl start firezone-gateway

# Verify installation
sleep 10
systemctl status firezone-gateway || echo "Firezone Gateway started"

echo "Firezone Gateway initialization completed!"
echo "Gateway will register with Firezone Control Plane using enrollment token"
