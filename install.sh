#!/bin/bash
set -e

echo "Starting MicroCP Installation..."
echo "================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this installer as root."
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    echo "Cannot detect OS. Only Debian 12/13 and Ubuntu 22.04/24.04 are supported."
    exit 1
fi

if [[ "$OS" == "ubuntu" && ("$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04") ]]; then
    echo "Detected Ubuntu $VERSION_ID"
elif [[ "$OS" == "debian" && ("$VERSION_ID" == "12" || "$VERSION_ID" == "13") ]]; then
    echo "Detected Debian $VERSION_ID"
else
    echo "Unsupported OS: $OS $VERSION_ID. Only Debian 12/13 and Ubuntu 22.04/24.04 are supported."
    exit 1
fi

# Set non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

echo "Updating system and installing dependencies..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget unzip tar jq ufw fail2ban certbot python3-certbot-nginx mariadb-server nginx sqlite3 python3-bcrypt

# PHP repository setup
if [[ "$OS" == "ubuntu" ]]; then
    apt-get install -y software-properties-common
    add-apt-repository ppa:ondrej/php -y
elif [[ "$OS" == "debian" ]]; then
    apt-get install -y lsb-release apt-transport-https ca-certificates curl
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
fi

apt-get update -y

echo "Installing PHP versions..."
PHP_VERSIONS=("8.1" "8.2" "8.3")
for VER in "${PHP_VERSIONS[@]}"; do
    apt-get install -y php${VER}-fpm php${VER}-mysql php${VER}-curl php${VER}-xml php${VER}-mbstring php${VER}-zip
done

echo "Installing WP-CLI..."
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Create required directories
echo "Creating MicroCP directories..."
mkdir -p /opt/microcp
mkdir -p /var/lib/microcp
mkdir -p /backup
mkdir -p /var/www

# Download latest MicroCP release
echo "Downloading latest MicroCP release..."
REPO="abirsiddiky/MicroCP"
LATEST_RELEASE=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url.*microcp_linux_amd64" | cut -d : -f 2,3 | tr -d \" | xargs)

if [ -z "$LATEST_RELEASE" ]; then
    echo "Warning: Could not fetch latest release URL. This might be because the repository is private or has no releases yet."
    echo "Attempting to build from source or copy local binary..."
    
    if [ -f "./microcp" ]; then
        cp ./microcp /opt/microcp/microcp
        chmod +x /opt/microcp/microcp
    else
        echo "MicroCP binary not found locally."
    fi
    
    if [ -d "./web" ]; then
        cp -r ./web /opt/microcp/
    fi
else
    # Download binary directly if available
    wget -qO /opt/microcp/microcp $LATEST_RELEASE
    chmod +x /opt/microcp/microcp
fi

# Generate admin credentials
ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 16)
SECRET_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64)

echo "Configuring MicroCP environment..."
cat > /etc/microcp.env <<EOF
MICROCP_PORT=8080
MICROCP_SECRET=$SECRET_KEY
EOF
chmod 600 /etc/microcp.env

# Hash password and insert into SQLite
echo "Generating secure admin credentials..."
python3 -c "
import sqlite3, bcrypt
password = b'${ADMIN_PASSWORD}'
hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')
conn = sqlite3.connect('/var/lib/microcp/microcp.db')
c = conn.cursor()
c.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
c.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (\"admin_password\", ?)', (hashed,))
conn.commit()
conn.close()
" || echo "Note: Could not set generated password. Default password may still be 'admin'."

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/microcp.service <<EOF
[Unit]
Description=MicroCP Web Hosting Control Panel
After=network.target mysql.service nginx.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/microcp
ExecStart=/opt/microcp/microcp
Restart=always
RestartSec=5
Environment=GIN_MODE=release
EnvironmentFile=-/etc/microcp.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable microcp

if [ -f "/opt/microcp/microcp" ]; then
    systemctl restart microcp
fi

# Configure UFW
echo "Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw --force enable

# Get public IP
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || echo "YOUR_SERVER_IP")

echo "========================================================"
echo "MicroCP Installation Completed Successfully!"
echo "========================================================"
echo "Panel URL: http://${PUBLIC_IP}:8080"
echo "Username:  admin"
echo "Password:  ${ADMIN_PASSWORD}"
echo "========================================================"
echo "Please save these credentials securely."
