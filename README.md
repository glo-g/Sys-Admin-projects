Ticket #1042: Internal Web Portal Recovery & User Provisioning

Scenario Overview

An internal web app hosting company documentation has gone offline after a server reboot. The Helpdesk escalated ticket #1042 to you:

"Users cannot access the internal documentation site at [http://192.168.56.101](http://192.168.56.101). Additionally, a new junior developer needs SSH access, and we need to make sure our backups are actually working.

System Environment

- OS: Rocky Linux 9 / Ubuntu Server 24.04 LTS
- Services: NGINX, OpenSSH, Firewalld/UFW, Systemd

Objectives Completed

1. User Provisioning & SSH Hardening

- Created `devs` user group and provisioned user `jdev`.
- Implemented key-based SSH authentication (`ed25519`) and enforced strict file permissions (`700` for `~/.ssh`, `600` for `authorized_keys`).
- Restricted password authentication and root SSH access in SSH daemon configurations.

2. Service Recovery & Troubleshooting

- Diagnosed web server outage using `systemctl status nginx` and `journalctl`.
- Resolved firewall port blockages by enabling HTTP/HTTPS traffic via `firewalld`/`ufw`.
- Configured `nginx` to automatically start on system boot.

3. Log Audit & Monitoring

- Verified successful user logins in `/var/log/secure` (or `/var/log/auth.log`).
- Checked system resource overhead (`df -h`, `free -m`, `ps aux`).

4. Backup & Disaster Recovery

- Developed a Bash script (`scripts/backup_web.sh`) to automatically compress `/var/www/html/` and append operational logs.
- Simulated data loss by purging site files and successfully restored from `.tar.gz` archive.
