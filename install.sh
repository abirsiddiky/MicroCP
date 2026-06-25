#!/bin/bash
set -e

echo "Starting MicroCP installation..."

# 1. Check OS (Simplified for this script)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: $PRETTY_NAME"
fi

# 2. Update apt and install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y nginx mariadb-server certbot python3-certbot-nginx ufw fail2ban wp-cli php8.2-fpm php8.2-mysql php8.2-curl php8.2-xml php8.2-mbstring php8.2-zip

# 4. Create directories
echo "Creating directories..."
mkdir -p /opt/microcp/
mkdir -p /var/lib/microcp/
mkdir -p /backup/
mkdir -p /var/www/

# 5. Copy binary (assuming it's built in the current directory)
echo "Installing MicroCP binary..."
if [ -f "./microcp" ]; then
    cp ./microcp /opt/microcp/microcp
    chmod +x /opt/microcp/microcp
else
    echo "Warning: microcp binary not found. Please run 'make build' and copy it manually."
fi

# Copy web assets if they exist
if [ -d "./web" ]; then
    cp -r ./web /opt/microcp/
fi

# 6. Install systemd service
echo "Configuring systemd service..."
if [ -f "./microcp.service" ]; then
    cp ./microcp.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable microcp
    systemctl restart microcp || echo "Service failed to start. Check binary/config."
fi

# 7. Configure UFW
echo "Configuring UFW firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
# Enable ufw non-interactively if disabled (be careful with this on real servers)
# ufw --force enable

echo "--------------------------------------------------------"
echo "MicroCP installed."
echo "Open http://YOUR_IP:8080 — default password: admin"
echo "--------------------------------------------------------"
