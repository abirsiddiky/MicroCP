#!/bin/bash
set -euo pipefail

echo "Starting MicroCP Uninstallation..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this uninstaller as root."
  exit 1
fi

echo "Stopping MicroCP service..."
systemctl stop microcp || true
systemctl disable microcp || true
rm -f /etc/systemd/system/microcp.service
systemctl daemon-reload

echo "Removing MicroCP directories..."
rm -rf /opt/microcp
rm -f /etc/microcp.env
rm -f /usr/local/bin/microcp

read -p "Do you want to delete all MicroCP data (including databases and websites)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing /var/lib/microcp..."
    rm -rf /var/lib/microcp
    echo "Removing /var/log/microcp..."
    rm -rf /var/log/microcp
    echo "Removing /var/www..."
    rm -rf /var/www
    echo "Removing /backup..."
    rm -rf /backup
    echo "Warning: Nginx, MariaDB, PHP-FPM, and other dependencies were NOT removed."
else
    echo "Data preserved in /var/lib/microcp, /var/log/microcp, /var/www, and /backup."
fi

echo "MicroCP Uninstallation Complete."
