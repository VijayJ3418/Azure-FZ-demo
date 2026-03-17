#!/bin/bash
set -e

echo "Starting Jenkins initialization..."

# Update system
yum update -y

# Install EPEL repository
yum install -y epel-release

# Install required packages
yum install -y \
  java-11-openjdk \
  java-11-openjdk-devel \
  git \
  wget \
  curl \
  openssl \
  nginx \
  net-tools

# Format and mount data disk
echo "Configuring data disk..."
DEVICE="/dev/sdc"
MOUNT_POINT="/var/lib/jenkins"

# Wait for disk to be available
sleep 10

# Partition the disk if not already partitioned
if ! sudo fdisk -l "$DEVICE" | grep -q "Docker"; then
  echo "n
p
1

t
83
w" | sudo fdisk "$DEVICE" || true
fi

# Format the disk
sudo mkfs.ext4 "$DEVICE"1 2>/dev/null || sudo mkfs.ext4 "$DEVICE" 2>/dev/null || true

# Mount the disk
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$DEVICE"1 "$MOUNT_POINT" || sudo mount "$DEVICE" "$MOUNT_POINT" || true

# Add to fstab for persistent mounting
DEVICE_UUID=$(sudo blkid -s UUID -o value "$DEVICE"1 || sudo blkid -s UUID -o value "$DEVICE")
echo "UUID=$DEVICE_UUID $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Install Jenkins
echo "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins java-11-openjdk-devel

# Set Jenkins home to use the data disk
sudo mkdir -p $MOUNT_POINT
sudo chown -R jenkins:jenkins $MOUNT_POINT
sudo chmod -R 755 $MOUNT_POINT

# Update Jenkins systemd service to use custom JENKINS_HOME
sudo sed -i 's|^JENKINS_HOME=.*|JENKINS_HOME=/var/lib/jenkins|' /etc/sysconfig/jenkins

# Configure Nginx as reverse proxy with HTTPS
cat > /etc/nginx/sites-available/jenkins <<'EOF'
upstream jenkins {
    server 127.0.0.1:8080;
}

server {
    listen 443 ssl http2 default_server;
    server_name _;

    ssl_certificate /etc/nginx/certs/jenkins.crt;
    ssl_certificate_key /etc/nginx/certs/jenkins.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;

        # Jenkins specific
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Create certificate directory
sudo mkdir -p /etc/nginx/certs

# Copy certificates (these would be provided via terraform)
# Note: In production, use Azure Key Vault for certificate management
echo "${certificate_path}" | base64 -d > /etc/nginx/certs/jenkins.crt
echo "${certificate_key_path}" | base64 -d > /etc/nginx/certs/jenkins.key
sudo chmod 600 /etc/nginx/certs/jenkins.key

# Enable Nginx
systemctl enable nginx
systemctl start nginx

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins initialization completed!"
