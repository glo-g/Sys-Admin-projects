# Linux Web Server Stack (Nginx + PHP-FPM + MySQL) with Monitoring

A self-hosted, monitored web server stack built from scratch on a Linux VPS — covering provisioning, hardening, a working LEMP application stack, TLS, and observability with Prometheus + Grafana.

## Overview

This project demonstrates end-to-end Linux system administration: provisioning a server, securing it, standing up a full web stack (Nginx → PHP-FPM → MySQL), enabling encrypted traffic, and monitoring server health — all set up manually first, then automated with a shell script for repeatable deployment.

**Live demo:** [link, if applicable]
**Stack:** Ubuntu [version] · Nginx · PHP-FPM [version] · MySQL/MariaDB · Prometheus · Grafana · UFW · Let's Encrypt

## Architecture

```
Browser
   │  HTTPS
   ▼
Nginx (reverse proxy, TLS termination, port 443)
   │
   ▼
PHP-FPM (application logic)
   │
   ▼
MySQL/MariaDB (data layer)

Node Exporter ──▶ Prometheus ──▶ Grafana (dashboards + alerts)
```

## Features

- **Provisioning & hardening**: non-root sudo user, SSH key-only auth, disabled root/password login, UFW firewall with least-privilege rules
- **Web stack**: Nginx configured as reverse proxy and static file server, PHP-FPM handling dynamic requests, MySQL/MariaDB as the data layer with a dedicated least-privilege app user
- **Security**: HTTPS via Let's Encrypt/Certbot with forced redirects, firewall restricted to required ports only
- **Monitoring**: Node Exporter exposing system metrics, Prometheus scraping them, Grafana dashboard tracking CPU, memory, disk, and uptime, with a basic alert for service downtime
- **Automation**: shell script to rebuild the entire stack from a clean server in one run

## Repository structure

```
.
├── app/                  # Sample PHP application code
├── nginx/                # Nginx server block config
├── mysql/                # Schema / seed data
├── monitoring/           # Prometheus config + Grafana dashboard JSON
├── scripts/
│   └── setup.sh          # Automated provisioning + install script
└── README.md
```

## Setup

### Prerequisites
- A Linux VPS (Ubuntu [version] recommended) with root/sudo access
- A domain name pointed at the server's IP (optional, needed for TLS)

### 1. Harden the server
```bash
adduser [username]
usermod -aG sudo [username]
# copy your SSH public key to ~/.ssh/authorized_keys
# then disable password + root login in /etc/ssh/sshd_config
sudo ufw allow OpenSSH
sudo ufw enable
sudo apt update && sudo apt upgrade -y
```

### 2. Install and configure Nginx
```bash
sudo apt install nginx -y
sudo ufw allow 'Nginx Full'
# add your server block, e.g. /etc/nginx/sites-available/[app-name]
sudo ln -s /etc/nginx/sites-available/[app-name] /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 3. Install PHP-FPM
```bash
sudo apt install php-fpm php-mysql -y
# point the Nginx server block's location ~ \.php$ block at the PHP-FPM socket
sudo systemctl restart nginx php[version]-fpm
```

### 4. Install and secure MySQL/MariaDB
```bash
sudo apt install mysql-server -y
sudo mysql_secure_installation
# create a dedicated database and least-privilege app user
```

### 5. Deploy the app
```bash
# copy app/ into your web root, e.g. /var/www/[app-name]
# import mysql/schema.sql into your database
```

### 6. Enable HTTPS
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d [yourdomain.com]
```

### 7. Set up monitoring
```bash
# install Node Exporter, Prometheus, and Grafana (see monitoring/ for configs)
# import monitoring/dashboard.json into Grafana
```

### Or, run it all at once
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## Monitoring

![Grafana dashboard screenshot](docs/grafana-dashboard.png)

Tracks CPU usage, memory usage, disk usage, and uptime, with an alert configured for [describe alert condition, e.g. service downtime > 1 min].

## What this project demonstrates

- Linux server administration and hardening fundamentals
- Configuring and connecting a multi-tier web stack (Nginx, PHP-FPM, MySQL)
- Basic networking and firewall management
- TLS/certificate management
- Observability with Prometheus and Grafana
- Infrastructure automation via shell scripting

## Future improvements

- [ ] Replace the manual setup script with an Ansible playbook
- [ ] Containerize the stack with Docker Compose
- [ ] Add centralized logging (e.g., Loki or the ELK stack)
- [ ] CI/CD pipeline for automated deployment on push

## Author

[Your Name] — [LinkedIn] · [GitHub]
