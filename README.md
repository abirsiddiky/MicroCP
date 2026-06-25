# MicroCP

A lightweight, beginner-friendly web hosting control panel built for low-resource VPS servers.

MicroCP is designed as a modern alternative to TinyCP and aaPanel Free, focusing on simplicity, performance, and ease of use. It is built for single-server, single-administrator environments and optimized for VPS instances with as little as 512 MB RAM.

## Features

### 📊 Real-Time Dashboard

Monitor your server in real time with live statistics:

* CPU Usage
* RAM Usage
* Swap Usage
* Disk Usage
* Network Traffic
* Upload / Download Speed
* Server Load Average
* System Uptime
* Active Connections
* Installed PHP Versions
* Website & Database Count

---

### 🌐 Website Management

Manage websites easily from a clean web interface.

Features:

* Create Website
* Delete Website
* Enable / Disable Website
* Suspend Website
* Change PHP Version
* Change Document Root
* Automatic Nginx Configuration
* Automatic PHP-FPM Pool Creation

---

### ⚡ Multi PHP Support

Run different PHP versions for different websites.

Supported Versions:

* PHP 7.4
* PHP 8.0
* PHP 8.1
* PHP 8.2
* PHP 8.3
* PHP 8.4
* PHP 8.5

Features:

* Per-site PHP version selection
* Isolated PHP-FPM pools
* Easy PHP version switching

---

### 🚀 One-Click WordPress Installer

Deploy WordPress in seconds.

Automatically:

* Downloads WordPress
* Creates Database
* Creates Database User
* Generates wp-config.php
* Configures Nginx
* Installs SSL Certificate

Additional Tools:

* Update WordPress Core
* Update Plugins
* Update Themes
* Enable / Disable Debug Mode
* Cache Management

---

### 🗄 Database Management

Built-in MariaDB management tools.

Features:

* Create Database
* Delete Database
* Create User
* Delete User
* Reset Password
* Import SQL
* Export SQL

No phpMyAdmin required.

---

### 📁 File Manager

Manage files directly from the browser.

Features:

* Upload Files
* Download Files
* Create Files & Folders
* Rename
* Copy
* Move
* Delete
* ZIP / Unzip
* Permission Management (chmod)

Built-in Monaco Editor support for:

* PHP
* HTML
* CSS
* JavaScript
* JSON
* XML
* Nginx Configuration Files

---

### 🔒 SSL Management

Integrated Let's Encrypt support.

Features:

* Issue SSL Certificate
* Renew SSL Certificate
* Revoke SSL Certificate
* Force HTTPS
* Automatic Renewal

---

### 💾 Backup Manager

Simple backup and restore system.

Features:

* Website Backup
* Database Backup
* Full Backup
* Restore Backup
* Download Backup

Compression Format:

* tar.gz

---

### ⏰ Cron Job Manager

Manage cron jobs from the web interface.

Features:

* Create Cron Jobs
* Edit Cron Jobs
* Delete Cron Jobs
* Enable / Disable Jobs

---

### 📜 Log Viewer

View logs directly from the control panel.

Supported Logs:

* Nginx Access Logs
* Nginx Error Logs
* PHP Logs
* System Logs

Features:

* Search
* Filter
* Live Tail Mode

---

### 🛡 Security Tools

#### Firewall Management

* UFW Integration
* Open Ports
* Close Ports
* View Active Rules

#### Fail2Ban Integration

* Enable / Disable
* Restart Service
* View Status

#### SSH Manager

* Change SSH Port
* Enable SSH Key Authentication
* Disable Password Authentication
* Disable Root Login

---

## System Requirements

Minimum:

* 1 CPU Core
* 512 MB RAM
* 10 GB SSD

Recommended:

* 2 CPU Cores
* 1 GB RAM
* 20 GB SSD

Supported Operating Systems:

* Debian 12
* Debian 13
* Ubuntu 22.04
* Ubuntu 24.04

---

## Technology Stack

### Backend

* Golang
* Gin
* SQLite
* WebSockets
* gopsutil

### Frontend

* Go HTML Templates
* HTMX
* Alpine.js

### Services

* Nginx
* MariaDB
* PHP-FPM
* Certbot
* Fail2Ban
* UFW

---

## Installation

One-command installation:

```bash
curl -fsSL https://raw.githubusercontent.com/abirsiddiky/MicroCP/main/install.sh | bash
```

After installation, MicroCP will display:

* Panel URL
* Admin Username
* Generated Password
* Service Status

---

## Design Goals

* Lightweight
* Beginner Friendly
* Low Resource Usage
* Fast Deployment
* Production Ready
* Secure by Default
* Minimal Dependencies

---

## Resource Usage Target

Idle Usage:

* RAM: 20–50 MB
* CPU: <1%
* Disk: <50 MB

Designed specifically for low-resource VPS environments.

---

## License

MIT License

---

## Author

Abir Siddiky
