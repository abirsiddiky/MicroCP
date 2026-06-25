#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/microcp/install.log"
mkdir -p /var/log/microcp
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

fail() {
    echo -e "\n[!] ERROR: $1"
    echo "Check the installation log at $LOG_FILE for details."
    exit 1
}

log "Starting MicroCP Installation..."
log "================================"

if [ "$EUID" -ne 0 ]; then
  fail "Please run this installer as root."
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    fail "Cannot detect OS. Only Debian 12/13 and Ubuntu 22.04/24.04 are supported."
fi

if [[ "$OS" == "ubuntu" && ("$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04") ]]; then
    log "Detected Ubuntu $VERSION_ID"
elif [[ "$OS" == "debian" && ("$VERSION_ID" == "12" || "$VERSION_ID" == "13") ]]; then
    log "Detected Debian $VERSION_ID"
else
    fail "Unsupported OS: $OS $VERSION_ID. Only Debian 12/13 and Ubuntu 22.04/24.04 are supported."
fi

export DEBIAN_FRONTEND=noninteractive

log "Updating system and installing dependencies..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget unzip tar jq ufw fail2ban certbot python3-certbot-nginx mariadb-server nginx sqlite3 python3-bcrypt git build-essential iproute2

if [[ "$OS" == "ubuntu" ]]; then
    apt-get install -y software-properties-common
    add-apt-repository ppa:ondrej/php -y
elif [[ "$OS" == "debian" ]]; then
    apt-get install -y lsb-release apt-transport-https ca-certificates curl
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
fi

apt-get update -y

log "Installing PHP versions..."
PHP_VERSIONS=("8.1" "8.2" "8.3")
for VER in "${PHP_VERSIONS[@]}"; do
    apt-get install -y php${VER}-fpm php${VER}-mysql php${VER}-curl php${VER}-xml php${VER}-mbstring php${VER}-zip || true
done

log "Installing WP-CLI..."
curl -sSO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

log "Creating MicroCP directories..."
mkdir -p /opt/microcp
mkdir -p /var/lib/microcp
mkdir -p /backup
mkdir -p /var/www

build_from_source() {
    log "Attempting to build from source..."
    if ! command -v go >/dev/null 2>&1; then
        log "Go is not installed. Installing Go..."
        wget -q https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
        rm go1.22.4.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    # Prevent OOM kills on low RAM VPS (specifically for modernc.org/sqlite)
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_RAM" -lt 2048 ]; then
        log "Low RAM detected (${TOTAL_RAM}MB). Setting up temporary swap for compilation to prevent OOM kills..."
        if [ ! -f /swapfile ]; then
            fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            log "Temporary swap enabled."
            SWAP_ADDED=1
        fi
    fi
    
    TEMP_DIR=$(mktemp -d)
    log "Cloning repository..."
    git clone https://github.com/abirsiddiky/MicroCP.git "$TEMP_DIR" || fail "Failed to clone repository"
    cd "$TEMP_DIR"
    
    log "Downloading go modules..."
    go mod tidy || fail "Failed to download Go modules"
    
    log "Building MicroCP (this may take a few minutes)..."
    if ! GOMAXPROCS=1 go build -p 1 -ldflags="-s -w" -o microcp ./cmd/microcp; then
        fail "Source build failed. The Go compiler encountered an error or ran out of memory."
    fi
    
    if [ ! -f "microcp" ]; then
        fail "Source build failed. Binary not found."
    fi
    
    install -m 755 microcp /opt/microcp/microcp
    cp -r web /opt/microcp/ || true
    
    cd /
    rm -rf "$TEMP_DIR"
    
    # Remove temporary swap if we added it
    if [ "${SWAP_ADDED:-0}" -eq 1 ]; then
        log "Removing temporary swap..."
        swapoff /swapfile || true
        rm -f /swapfile || true
    fi
    
    return 0
}

log "Downloading latest MicroCP release..."
REPO="abirsiddiky/MicroCP"
LATEST_RELEASE=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url.*microcp_linux_amd64" | cut -d : -f 2,3 | tr -d \" | xargs || true)

if [ -n "$LATEST_RELEASE" ]; then
    log "Downloading binary from $LATEST_RELEASE"
    wget -qO microcp "$LATEST_RELEASE" || true
    if [ -f "microcp" ] && [ -s "microcp" ]; then
        install -m 755 microcp /opt/microcp/microcp
        rm microcp
    else
        log "Download failed or file is empty."
        build_from_source
    fi
else
    log "Warning: Could not fetch latest release URL."
    build_from_source
fi

if [ ! -f /opt/microcp/microcp ]; then
    fail "Installation failed. /opt/microcp/microcp does not exist."
fi

if [ ! -x /opt/microcp/microcp ]; then
    fail "Installation failed. /opt/microcp/microcp is not executable."
fi

ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 16)
SECRET_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64)

log "Configuring MicroCP environment..."
cat > /etc/microcp.env <<EOF
MICROCP_PORT=8080
MICROCP_SECRET=$SECRET_KEY
EOF
chmod 600 /etc/microcp.env

log "Generating secure admin credentials..."
python3 -c "
import sqlite3, bcrypt, sys
try:
    password = b'${ADMIN_PASSWORD}'
    hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')
    conn = sqlite3.connect('/var/lib/microcp/microcp.db')
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
    c.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (\"admin_password\", ?)', (hashed,))
    conn.commit()
    conn.close()
except Exception as e:
    print(f'Error setting password: {e}', file=sys.stderr)
    sys.exit(1)
" || log "Note: Could not set generated password in database. Default password may still be 'admin'."

log "Creating systemd service..."
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

log "Starting service..."
systemctl daemon-reload
systemctl enable microcp
systemctl restart microcp

log "Waiting 5 seconds for service startup..."
sleep 5

log "Validating service status..."
if ! systemctl is-active --quiet microcp; then
    journalctl -u microcp -n 20 --no-pager
    fail "MicroCP service failed to start or crashed."
fi

log "Validating listening port..."
if ! ss -tulpn | grep ":8080 " > /dev/null; then
    fail "MicroCP is not listening on port 8080."
fi

log "Validating HTTP response..."
if ! curl -s http://127.0.0.1:8080 >/dev/null; then
    fail "MicroCP did not respond to HTTP request on port 8080."
fi

log "Configuring firewall..."
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 8080/tcp || true
ufw --force enable || true

log "Installing microcp CLI tools..."
cat > /usr/local/bin/microcp <<'EOF'
#!/bin/bash
if [ "$1" == "doctor" ]; then
    echo "=== MicroCP System Health Check ==="
    
    echo -n "Binary check: "
    if [ -x /opt/microcp/microcp ]; then echo "OK"; else echo "FAILED (Not found or not executable)"; fi
    
    echo -n "Service status: "
    if systemctl is-active --quiet microcp; then echo "OK (Active)"; else echo "FAILED (Inactive/Dead)"; fi
    
    echo -n "Port 8080: "
    if ss -tulpn | grep ":8080 " > /dev/null; then echo "OK (Listening)"; else echo "FAILED (Not listening)"; fi
    
    echo -n "Database (SQLite): "
    if [ -f /var/lib/microcp/microcp.db ]; then echo "OK"; else echo "FAILED (Not found)"; fi
    
    echo -n "Nginx status: "
    if systemctl is-active --quiet nginx; then echo "OK (Active)"; else echo "FAILED (Inactive)"; fi
    
    echo -n "MariaDB status: "
    if systemctl is-active --quiet mariadb; then echo "OK (Active)"; else echo "FAILED (Inactive)"; fi
    
    echo -n "PHP 8.2-FPM status: "
    if systemctl is-active --quiet php8.2-fpm; then echo "OK (Active)"; else echo "WARNING (Inactive or not installed)"; fi

    exit 0
fi

echo "Usage: microcp doctor"
EOF
chmod +x /usr/local/bin/microcp

PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || echo "YOUR_SERVER_IP")

echo "========================================================"
echo "MicroCP Installation Completed Successfully!"
echo "========================================================"
echo "Panel URL: http://${PUBLIC_IP}:8080"
echo "Username:  admin"
echo "Password:  ${ADMIN_PASSWORD}"
echo "========================================================"
echo "Please save these credentials securely."

