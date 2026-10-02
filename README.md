# Secure Multi-Service Server Build (Rocky Linux)
# RockSolid

**Building a secure, multi-service server on Rocky Linux.**

A hands-on system administration project where I turn a blank Rocky Linux virtual machine into a secure, monitored, backed-up server running multiple services, and document every step so it can be rebuilt by someone else.

---

## Table of Contents

1. [Overview](#overview)
2. [The Problem](#the-problem)
3. [Scenario and Requirements](#scenario-and-requirements)
4. [Why Rocky Linux](#why-rocky-linux)
5. [Environment](#environment)
6. [Skills Demonstrated](#skills-demonstrated)
7. [Project Roadmap](#project-roadmap)
8. [Build Log](#build-log)
9. [Troubleshooting Log](#troubleshooting-log)
10. [Lessons Learned](#lessons-learned)

---

## Overview

This project simulates the work a junior system administrator does when a business asks for a new server. Instead of a single clever trick, it covers the full lifecycle: initial setup, hardening, user management, services, storage, automation, monitoring and documentation.

## The Problem

A default server install is not ready for real use. Out of the box it is typically:

- **Insecure**: open ports, password logins, root access, unpatched packages
- **Unstructured**: shared accounts and unclear permissions
- **Fragile**: no backups and no monitoring, so problems are found by users instead of admins
- **Undocumented**: only one person knows how it was built

This project solves those problems by building a server that is secure, reliable and reproducible.

| Part of the project | Problem it solves |
|---|---|
| Hardening (SSH keys, no root login, updates) | Blocks common attacks such as password brute-forcing and known vulnerabilities |
| Users, groups and permissions | Enforces least privilege and limits damage if an account is compromised |
| Firewall, SELinux, fail2ban | Layered defence, so one failed control does not expose the server |
| Web server and services | Delivers the business value the server exists for |
| LVM storage | Allows disk space to grow without downtime |
| Backup scripts and scheduling | Protects against data loss, hardware failure and ransomware |
| Monitoring and logs | Detects issues (full disks, failed logins) before they become outages |
| Documentation (and optional Ansible) | Makes the setup repeatable and understandable by others |

## Scenario and Requirements

**Scenario:** A small company needs a server to host its internal website and provide shared file storage for its team. The IT team has one Rocky Linux VM and needs it ready for production use.

**Requirements:**

| # | Requirement | Area |
|---|---|---|
| R1 | The system must be fully updated and use a fixed hostname and timezone | Setup |
| R2 | Only authorised staff can log in, using SSH keys; root login is disabled | Security |
| R3 | Staff are organised into groups with access only to what they need | Access control |
| R4 | Only required network ports are open | Security |
| R5 | SELinux must remain in enforcing mode | Security |
| R6 | Repeated failed logins must trigger an automatic ban | Security |
| R7 | The server must host a working web service | Services |
| R8 | Storage must be expandable without downtime | Storage |
| R9 | Data must be backed up automatically every day | Automation |
| R10 | Admins must be able to check system health and review logs | Monitoring |
| R11 | Every step must be documented so the build can be repeated | Documentation |

## Why Rocky Linux

Rocky Linux is a free, community-maintained rebuild of Red Hat Enterprise Linux (RHEL). It uses the same package manager (`dnf`), file layout, SELinux, `firewalld` and `systemd` as RHEL, so the skills practised here transfer directly to enterprise environments that run RHEL, AlmaLinux or Oracle Linux.

## Environment

| Item | Detail |
|---|---|
| Operating system | Rocky Linux |
| Hypervisor | VirtualBox | 
| Network mode | Bridged |
| Host machine | Kali Linux_|

**Confirm the OS version:**

```bash
cat /etc/os-release
hostnamectl
```
## Skills Demonstrated

- Linux installation and configuration (RHEL family)
- User, group and permission management (including ACLs)
- SSH hardening and key-based authentication
- Firewall configuration (`firewalld`) and SELinux administration
- Intrusion prevention with `fail2ban`
- Web server deployment and configuration
- Disk partitioning, LVM and persistent mounts
- Bash scripting and task scheduling (`cron` / `systemd` timers)
- Log analysis and system monitoring
- Troubleshooting and technical documentation

## Project Roadmap

Tick each phase off as it is completed.

- [x] **Phase 1: Initial setup and updates** (R1)
- [x] **Phase 2: Users, groups and permissions** (R3)
- [x] **Phase 3: SSH hardening** (R2)
- [x] **Phase 4: Firewall, SELinux and fail2ban** (R4, R5, R6)
- [x] **Phase 5: Web service** (R7)
- [x] **Phase 6: Storage with LVM** (R8)
- [x] **Phase 7: Backup automation** (R9)
- [x] **Phase 8: Monitoring and logging** (R10)
- [x] **Phase 9: Final review and (optional) Ansible automation** (R11)

## Build Log

Each phase will be added below as it is completed:

### Phase 1: Initial Setup and Updates

- **Goal:** Start from a fully patched, correctly named system with the right time, so every later phase builds on a stable base. Meets **R1**.

**Steps**

1. **Recorded the starting state** to know what I was working with.
   ```bash

   cat /etc/os-release

![OS version and hostname](/screenshots/catos.png)

hostnamectl
  
![VM settings](/screenshots/vmdetails.png)
   
2. **Updated the system.** Unpatched packages are one of the most common ways servers get compromised.
   ```bash
   sudo dnf check-update
   sudo dnf update -y
   ```

3. **Checked whether a reboot was needed** 
   ```sudo dnf needs-restarting -r
   sudo reboot   # only if required
   ```

4. **Installed baseline tools.** EPEL provides extra packages needed later (`fail2ban`, `htop`), and `policycoreutils-python-utils` provides `semanage` for SELinux.
   ```bash
   sudo dnf install -y epel-release
   sudo dnf install -y vim nano wget curl tar rsync bash-completion htop net-tools policycoreutils-python-utils
   ```

5. **Set the hostname** to something clear and descriptive.
   ```bash
   sudo hostnamectl set-hostname HOSTNAME_HERE
   ```

**Verification**

- [x] System fully updated and rebooted if required
- [x] `hostnamectl` shows the new hostname


**Result:** R1 met. The server is patched, named, on the correct time, and has a known network address.

---

### Phase 2: Users, Groups and Permissions

- **Goal:** Stop using a single shared/root account. Give each person their own login and access only to what they need (least privilege). Meets **R3**.

**Steps**

1. **Created an admin user with sudo rights**, and stopped working as root from this point on.
   ```bash
   sudo useradd -m -G wheel adminuser
   sudo passwd adminuser
   su - adminuser
   sudo whoami   # returns "root"
   ```
   > 📸 **Screenshot 6:** `id adminuser` and `sudo whoami` returning `root`
   >
   > Save as `images/06-admin-user.png`

   ![Admin user with sudo](images/06-admin-user.png)

2. **Created groups** for each team that needs distinct access.
   ```bash
   sudo groupadd developers
   sudo groupadd webteam
   ```

3. **Created staff users** and assigned each to the relevant group. Neither has sudo rights.
   ```bash
   sudo useradd -m -G developers alice
   sudo useradd -m -G webteam bob
   sudo passwd alice
   sudo passwd bob
   ```

4. **Created a shared directory for the developers group**, owned by the group with setgid so new files always inherit `developers` ownership.
   ```bash
   sudo mkdir -p /srv/shared/dev
   sudo chown root:developers /srv/shared/dev
   sudo chmod 2770 /srv/shared/dev
   ```

5. **Gave the web team read-only access via an ACL**, since standard Unix permissions only support one group per directory.
   ```bash
   sudo setfacl -m g:webteam:rx /srv/shared/dev
   sudo setfacl -d -m g:webteam:rx /srv/shared/dev
   ```
   > 📸 **Screenshot 7:** `ls -ld /srv/shared/dev` and `getfacl /srv/shared/dev`
   >
   > Save as `images/07-shared-dir-acl.png`

   ![Shared directory ACL](images/07-shared-dir-acl.png)

6. **Verified the permission model with real tests.**
   ```bash
   sudo -u alice touch /srv/shared/dev/report.txt   # succeeds
   sudo -u bob ls /srv/shared/dev                    # succeeds (read-only)
   sudo -u bob touch /srv/shared/dev/hack.txt        # denied
   ```
   > 📸 **Screenshot 8:** the three test commands, including Bob's "Permission denied"
   >
   > Save as `images/08-permission-test.png`

   ![Permission test results](images/08-permission-test.png)

7. **(Optional) Set password ageing** on staff accounts as a basic account-hygiene control.
   ```bash
   sudo chage -M 90 -W 7 alice
   ```

**Verification**

- [x] `adminuser` can run `sudo whoami` and gets `root`
- [x] `id alice` and `id bob` show the correct group membership
- [x] Alice (developers) can write to `/srv/shared/dev`
- [x] Bob (webteam) can read but not write to `/srv/shared/dev`
- [x] New files in the directory inherit the `developers` group (setgid working)

**Result:** R3 met. Access is now split by role instead of shared, and I've stopped administering the box as root.

---

### Phase 3: SSH Hardening

- **Goal:** Remove the ability to log in with a guessable password, and remove root as a remote login target entirely. Only authorised key-holders can reach the server. Meets **R2**.

**Steps**

1. **Generated an SSH key pair on the local (host) machine**, not the VM.
   ```bash
   ssh-keygen -t ed25519 -C "adminuser@rocksolid"
   ```

2. **Switched the VM's network adapter from NAT to Bridged**, so the host machine could reach the VM directly on the home network. This was a real troubleshooting step — see the [Troubleshooting Log](#troubleshooting-log).

3. **Copied the public key to the VM** and confirmed key-based login worked before changing any server settings.
   ```bash
   ssh-copy-id adminuser@192.168.1.66
   ssh adminuser@192.168.1.66
   ```
   > 📸 **Screenshot 9:** successful SSH login using the key, no password prompt
   >
   > Save as `images/09-ssh-key-login.png`

   ![SSH key login](images/09-ssh-key-login.png)

4. **Backed up the SSH config** before editing it.
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
   ```

5. **Hardened `sshd_config`**, disabling root login and password authentication entirely.
   ```
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   PermitEmptyPasswords no
   MaxAuthTries 3
   ```

6. **Validated the config before restarting the service**, to avoid a syntax error locking me out.
   ```bash
   sudo sshd -t
   ```

7. **Restarted SSH, keeping the original session open** as a safety net, and confirmed key login still worked in a brand new session before closing the first one.
   ```bash
   sudo systemctl restart sshd
   ssh adminuser@192.168.1.66
   ```

8. **Confirmed root and password logins were now blocked.**
   ```bash
   ssh root@192.168.1.66   # refused immediately
   ```
   > 📸 **Screenshot 10:** `sshd -t` with no errors, and the refused root login attempt
   >
   > Save as `images/10-ssh-hardened.png`

   ![SSH hardened](images/10-ssh-hardened.png)

9. **Decision: kept the default SSH port (22).** I considered moving to a non-standard port (e.g. 2222) but decided against it for this build:
   - Changing the port only reduces automated/casual scanning; it doesn't stop a real port scan and isn't a substitute for real controls
   - The actual protection here comes from key-only authentication (this phase) and `fail2ban` (Phase 4)
   - Changing ports requires coordinating a firewall rule update first, which adds lockout risk for limited benefit at this stage

   This can be revisited later by opening the new port in `firewalld` before changing `sshd_config`, to avoid a lockout.

**Verification**

- [x] Key-based login works for `adminuser`
- [x] `sshd -t` reports no config errors
- [x] Root SSH login is refused
- [x] Password SSH login is refused
- [x] Kept a working session open during the change as a rollback safety net

**Result:** R2 met. The server can only be accessed by holders of an authorised private key, and root cannot log in remotely at all.

---

### Phase 4: Firewall, SELinux, and fail2ban

- **Goal:** Add layered defence so that if one control fails, the others still protect the server: a firewall to control what's reachable, SELinux to contain what a process can do even if compromised, and fail2ban to stop repeated login attempts. Meets **R4**, **R5**, **R6**.

**Steps**

1. **Checked the current firewall state.** Rocky ships with `firewalld` enabled by default.
   ```bash
   sudo firewall-cmd --state
   sudo firewall-cmd --list-all
   ```
   > 📸 **Screenshot 11:** `firewall-cmd --list-all` before changes
   >
   > Save as `images/11-firewall-status.png`

   ![Firewall status](images/11-firewall-status.png)

2. **Opened only the services needed**, in preparation for the web server in Phase 5, and made the rules persist across reboots.
   ```bash
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --reload
   ```
   > 📸 **Screenshot 12:** `firewall-cmd --list-all` showing ssh, http, https allowed
   >
   > Save as `images/12-firewall-rules.png`

   ![Firewall rules](images/12-firewall-rules.png)

3. **Confirmed SELinux is enforcing**, rather than disabled or permissive (a common shortcut that removes an entire security layer).
   ```bash
   getenforce
   sestatus
   ```
   > 📸 **Screenshot 13:** `sestatus` showing "Enforcing"
   >
   > Save as `images/13-selinux-status.png`

   ![SELinux status](images/13-selinux-status.png)

4. **Installed SELinux troubleshooting tools**, ready to diagnose and fix a real denial once the web server exists in Phase 5.
   ```bash
   sudo dnf install -y setroubleshoot-server
   sudo ausearch -m avc -ts recent
   ```

5. **Installed and enabled fail2ban** to automatically block repeated failed login attempts.
   ```bash
   sudo dnf install -y fail2ban
   sudo systemctl enable --now fail2ban
   ```

6. **Configured an SSH jail** using a local override file (never edit `jail.conf` directly, since updates can overwrite it).
   ```
   [sshd]
   enabled = true
   port = ssh
   filter = sshd
   maxretry = 3
   findtime = 10m
   bantime = 1h
   ```
   ```bash
   sudo systemctl restart fail2ban
   ```

7. **Verified the ban actually works** by deliberately failing SSH login 3+ times from another machine, then confirming the IP was banned and the connection subsequently refused.
   ```bash
   sudo fail2ban-client status sshd
   ```
   > 📸 **Screenshot 14:** `fail2ban-client status sshd` showing a banned IP
   >
   > Save as `images/14-fail2ban-banned.png`

   ![fail2ban banned IP](images/14-fail2ban-banned.png)

**Verification**

- [x] `firewall-cmd --list-all` shows only intended services (ssh, http, https)
- [x] `getenforce` returns `Enforcing`
- [x] `fail2ban-client status sshd` shows the jail active
- [x] A real ban was triggered, confirmed, and reversed

**Result:** R4, R5 and R6 met. Only required ports are reachable, SELinux remains enforcing, and repeated failed logins are automatically blocked.

---

### Phase 5: Web Service

- **Goal:** Deliver the actual reason the server exists — a reachable website — and use SELinux to contain what the web server process is allowed to touch. Meets **R7**.

**Steps**

1. **Installed and enabled Nginx.**
   ```bash
   sudo dnf install -y nginx
   sudo systemctl enable --now nginx
   ```

2. **Confirmed it worked, first locally then from the host machine's browser** over the HTTP rule opened in Phase 4.
   ```bash
   curl http://localhost
   ```
   > 📸 **Screenshot 15:** the default Nginx page loading in the host browser
   >
   > Save as `images/15-nginx-default.png`

   ![Default Nginx page](images/15-nginx-default.png)

3. **Replaced the default page** with a simple custom one identifying the server.

4. **Moved the site to a non-standard content directory** (`/srv/website` instead of `/usr/share/nginx/html`), which is common in real deployments, and updated `root` in `nginx.conf` to match.

5. **Hit a real SELinux denial (403 Forbidden)** when reloading the site, because the new directory didn't carry the correct SELinux context even though standard file permissions were fine.
   > 📸 **Screenshot 16:** 403 Forbidden error in the browser
   >
   > Save as `images/16-selinux-403.png`

   ![SELinux 403 error](images/16-selinux-403.png)

6. **Confirmed the cause via `ausearch`**, rather than guessing.
   ```bash
   sudo ausearch -m avc -ts recent
   ```
   > 📸 **Screenshot 17:** `ausearch` output showing the `avc: denied` entry for `httpd_t`
   >
   > Save as `images/17-selinux-denial.png`

   ![SELinux denial in ausearch](images/17-selinux-denial.png)

7. **Fixed it the correct way**, by labelling the directory rather than disabling SELinux.
   ```bash
   sudo semanage fcontext -a -t httpd_sys_content_t "/srv/website(/.*)?"
   sudo restorecon -Rv /srv/website
   ```

8. **Verified the fix**, confirming the site loaded correctly and no new denials appeared.
   > 📸 **Screenshot 18:** site loading correctly, and `ls -Z /srv/website` showing the corrected context
   >
   > Save as `images/18-selinux-fixed.png`

   ![SELinux fixed, site loading](images/18-selinux-fixed.png)

**Verification**

- [x] Nginx running and enabled on boot
- [x] Site reachable from the host machine's browser
- [x] A real SELinux denial was triggered and confirmed via `ausearch`
- [x] Fixed correctly using `semanage`/`restorecon`, not by disabling SELinux
- [x] Confirmed no further denials after the fix

**Result:** R7 met. The server now delivers actual business value (a working website), and SELinux was proven to be doing real work rather than just left in its default state.

---

### Phase 6: Storage with LVM

- **Goal:** Make storage expandable without downtime, instead of being stuck with a fixed-size partition that causes an outage when it fills up. Meets **R8**.

**Steps**

1. **Took a snapshot before making any changes**, then shut down the VM and added a second virtual disk in VirtualBox (Settings → Storage → Add Hard Disk).

2. **Identified the new, unpartitioned disk.**
   ```bash
   lsblk
   ```
   > 📸 **Screenshot 19:** `lsblk` showing the new disk with no partitions
   >
   > Save as `images/19-new-disk.png`

   ![New disk](images/19-new-disk.png)

3. **Created a physical volume** on the new disk, marking it as usable by LVM.
   ```bash
   sudo pvcreate /dev/sdb
   ```

4. **Created a volume group**, a pool of storage that logical volumes are carved out of.
   ```bash
   sudo vgcreate data_vg /dev/sdb
   ```

5. **Created a logical volume**, deliberately leaving unused space in the volume group so it could be demonstrated growing later.
   ```bash
   sudo lvcreate -L 2G -n data_lv data_vg
   ```

6. **Formatted and mounted it.**
   ```bash
   sudo mkfs.xfs /dev/data_vg/data_lv
   sudo mkdir -p /srv/data
   sudo mount /dev/data_vg/data_lv /srv/data
   ```
   > 📸 **Screenshot 20:** `df -h /srv/data` showing the mounted volume
   >
   > Save as `images/20-lvm-mounted.png`

   ![LVM mounted](images/20-lvm-mounted.png)

7. **Made the mount permanent** via `/etc/fstab`, using the volume's UUID (found with `blkid`) rather than a device name, since device names like `/dev/sdb` can shift between boots.
   ```
   UUID=da7eab32-9216-49f8-a0ca-f87a6d492b50   /srv/data   xfs   defaults   0 0
   ```
   Verified without rebooting:
   ```bash
   sudo umount /srv/data
   sudo mount -a
   df -h /srv/data
   ```
   > 📸 **Screenshot 21:** `cat /etc/fstab` showing the entry, and `df -h` confirming it mounted via `mount -a`
   >
   > Save as `images/21-fstab-entry.png`

   ![fstab entry](images/21-fstab-entry.png)

8. **Extended the volume live**, with the filesystem mounted and in use the whole time — this is the actual benefit of LVM over a plain partition.
   ```bash
   sudo lvextend -L +1G /dev/data_vg/data_lv
   sudo xfs_growfs /srv/data
   ```
   > 📸 **Screenshot 22:** `df -h /srv/data` before and after, showing the size increase with no unmount and no downtime
   >
   > Save as `images/22-lvm-extended.png`

   ![LVM extended live](images/22-lvm-extended.png)

**Verification**

- [x] `lsblk` shows the LVM stack (PV → VG → LV)
- [x] The volume is mounted at `/srv/data`
- [x] The mount survives a reboot (persisted via `/etc/fstab` with UUID)
- [x] The volume was extended live, with no downtime

**Result:** R8 met. Storage can now grow on demand without taking the server offline.

---

### Phase 7: Backup Automation

- **Goal:** Protect against data loss from mistakes, hardware failure, or ransomware by automatically backing up the website and data volume every day, and proving the backups can actually be restored. Meets **R9**.

**Steps**

1. **Created a backup destination** separate from the data it protects.
   ```bash
   sudo mkdir -p /srv/backups
   ```

2. **Wrote a backup script** (`/opt/scripts/backup.sh`) that archives `/srv/website` and `/srv/data` with timestamps, logs the result, and prunes anything older than the 7 most recent backups of each type so the backup disk doesn't fill up over time.

3. **Tested it manually** before automating it.
   ```bash
   sudo chmod +x /opt/scripts/backup.sh
   sudo /opt/scripts/backup.sh
   ```
   > 📸 **Screenshot 23:** `ls -lh /srv/backups` showing the archives, and the log file contents
   >
   > Save as `images/23-backup-manual-test.png`

   ![Backup manual test](images/23-backup-manual-test.png)

4. **Scheduled it with a systemd timer** rather than plain cron, for better logging via `journalctl`.
   ```ini
   # /etc/systemd/system/rocksolid-backup.service
   [Unit]
   Description=RockSolid daily backup

   [Service]
   Type=oneshot
   ExecStart=/opt/scripts/backup.sh
   ```
   ```ini
   # /etc/systemd/system/rocksolid-backup.timer
   [Unit]
   Description=Run RockSolid backup daily

   [Timer]
   OnCalendar=daily
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```
   `Persistent=true` ensures a missed run (e.g. VM was off) executes as soon as the system is back up, instead of being silently skipped.
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now rocksolid-backup.timer
   ```
   > 📸 **Screenshot 24:** `systemctl list-timers` showing the next scheduled run
   >
   > Save as `images/24-backup-timer.png`

   ![Backup timer scheduled](images/24-backup-timer.png)

5. **Forced a run through the automation path** (not just the script directly) to prove the systemd service/timer actually works end to end.
   ```bash
   sudo systemctl start rocksolid-backup.service
   journalctl -u rocksolid-backup.service --since "5 minutes ago"
   ```
   > 📸 **Screenshot 25:** `journalctl` output showing the service ran successfully
   >
   > Save as `images/25-backup-run-log.png`

   ![Backup run logged](images/25-backup-run-log.png)

6. **Found and fixed a quoting bug in the pruning logic.** Running the script with `bash -x` revealed:
   ```
   ls -1t '/srv/backups/website-*.tar.gz'
   ls: cannot access '/srv/backups/website-*.tar.gz': No such file or directory
   ```
   The wildcard `*` had ended up inside the quotes, so bash treated it as a literal filename instead of expanding it. Fixed by moving the closing quote so only the variable is quoted:
   ```bash
   ls -1t "$BACKUP_DIR"/website-*.tar.gz | tail -n +8 | xargs -r rm --
   ls -1t "$BACKUP_DIR"/data-*.tar.gz | tail -n +8 | xargs -r rm --
   ```

7. **Proved the pruning logic actually works**, rather than assuming it did. With only a handful of real backups, the "keep last 7" rule has nothing to prune yet, so this was tested by creating fake aged files and confirming the oldest were removed correctly:
   ```bash
   for i in {1..8}; do sudo touch /srv/backups/website-fake-$i.tar.gz; done
   sudo /opt/scripts/backup.sh
   ls -lt /srv/backups/website-*.tar.gz   # oldest fake files removed, 7 kept
   ```
   Test files were removed afterward so they wouldn't be mistaken for real backups.

8. **Tested a real restore**, since an untested backup isn't a real backup.
   ```bash
   mkdir /tmp/restore-test && cd /tmp/restore-test
   sudo tar -xzf /srv/backups/website-<timestamp>.tar.gz
   ```
   > 📸 **Screenshot 26:** restored files in `/tmp/restore-test`, confirming the backup is valid
   >
   > Save as `images/26-restore-test.png`

   ![Restore test](images/26-restore-test.png)

**Verification**

- [x] Script runs manually without errors and produces two archives
- [x] Pruning logic verified with simulated aged files (bug found and fixed)
- [x] The systemd timer is enabled and shows a scheduled next run
- [x] A real restore was tested and confirmed to work

**Result:** R9 met. The server backs itself up daily without manual intervention, old backups are pruned automatically, and a restore has actually been proven to work, not just assumed.

---

### Phase 8: Monitoring and Logging

- **Goal:** Gain visibility into disk, memory, network and login activity, so problems are caught early instead of being reported by users after the fact. Meets **R10**.

**Steps**

1. **Checked disk usage** across all mounted volumes, particularly `/srv/website`, `/srv/data` and `/srv/backups`, since these are most likely to fill up over time.
   ```bash
   df -h
   ```
   > 📸 **Screenshot 27:** `df -h` output across all mounted volumes
   >
   > Save as `images/27-disk-usage.png`

   ![Disk usage](images/27-disk-usage.png)

2. **Checked memory and CPU usage.**
   ```bash
   free -h
   htop
   ```
   > 📸 **Screenshot 28:** `free -h` and `htop` running
   >
   > Save as `images/28-memory-cpu.png`

   ![Memory and CPU](images/28-memory-cpu.png)

3. **Reviewed active network connections**, confirming only the expected services (SSH, HTTP, HTTPS) were listening, matching the firewall rules from Phase 4.
   ```bash
   sudo ss -tulnp
   ```
   > 📸 **Screenshot 29:** `ss -tulnp` output
   >
   > Save as `images/29-network-connections.png`

   ![Network connections](images/29-network-connections.png)

4. **Reviewed authentication logs** for failed login attempts and fail2ban activity.
   ```bash
   sudo journalctl -u sshd --since "1 hour ago"
   sudo grep "Failed password" /var/log/secure
   sudo journalctl -u fail2ban --since "today"
   ```
   > 📸 **Screenshot 30:** evidence of failed login attempts and/or fail2ban activity
   >
   > Save as `images/30-auth-logs.png`

   ![Auth logs](images/30-auth-logs.png)

5. **Confirmed log rotation was configured**, rather than assuming it, so logs don't grow unbounded.
   ```bash
   cat /etc/logrotate.conf
   ls /etc/logrotate.d/
   ```

6. **Wrote a disk-space alert script**, reusing the scripting and scheduling pattern from Phase 7 but applied to a different problem — catching a filling disk before it becomes an outage.
   ```bash
   #!/bin/bash
   THRESHOLD=80
   LOGFILE="/var/log/rocksolid-diskcheck.log"

   df -h --output=pcent,target | tail -n +2 | while read -r line; do
       usage=$(echo "$line" | awk '{print $1}' | tr -d '%')
       mount=$(echo "$line" | awk '{print $2}')
       if [ "$usage" -ge "$THRESHOLD" ]; then
           echo "[$(date)] WARNING: $mount is at ${usage}% usage" >> "$LOGFILE"
       fi
   done
   ```
   Tested by temporarily lowering `THRESHOLD` to confirm the warning actually triggers, not just that the script runs without error.
   > 📸 **Screenshot 31:** the script running and triggering a warning during testing
   >
   > Save as `images/31-disk-alert-test.png`

   ![Disk alert test](images/31-disk-alert-test.png)

**Verification**

- [x] Can report current disk, memory and CPU usage on demand
- [x] Confirmed which ports are listening and matched them to firewall rules
- [x] Found failed login attempts and fail2ban activity in logs
- [x] Log rotation confirmed active
- [x] Disk-space alert script tested and confirmed to trigger correctly

**Result:** R10 met. The server's health and security activity are now visible on demand, and a basic alerting script catches a filling disk before it causes an outage.

---

### Phase 9: Final Review

- **Goal:** Confirm every requirement is actually met, not assumed, and leave behind documentation good enough for someone else to rebuild this server from scratch. Meets **R11**.

**Requirements review**

| # | Requirement | Status |
|---|---|---|
| R1 | System updated, fixed hostname and timezone | ✅ Met — Phase 1 |
| R2 | Only authorised staff can log in, via SSH keys; root login disabled | ✅ Met — Phase 3 |
| R3 | Staff organised into groups with access only to what they need | ✅ Met — Phase 2 |
| R4 | Only required network ports open | ✅ Met — Phase 4 |
| R5 | SELinux remains in enforcing mode | ✅ Met — Phase 4, Phase 5 |
| R6 | Repeated failed logins trigger an automatic ban | ✅ Met — Phase 4 |
| R7 | Server hosts a working web service | ✅ Met — Phase 5 |
| R8 | Storage is expandable without downtime | ✅ Met — Phase 6 |
| R9 | Data is backed up automatically every day | ✅ Met — Phase 7 |
| R10 | Admins can check system health and review logs | ✅ Met — Phase 8 |
| R11 | Every step documented so the build can be repeated | ✅ Met — this README |

**On Ansible automation (optional, not done)**

A natural next step for this project would be writing an Ansible playbook to automate the entire build end to end, turning this README into executable infrastructure-as-code rather than a manual runbook. This wasn't implemented here, since it introduces a new tool on top of an already broad project, but it's a clear direction for future work and the project is structured (one phase, one clear goal each) in a way that would map cleanly onto Ansible roles.

**Result:** R11 met. All 11 requirements are satisfied and verified, and the project is documented step by step with real commands, real screenshots, and real problems encountered and fixed along the way.

## Troubleshooting Log

A record of real problems hit during the build and how they were fixed.

| Problem | Symptom | Cause | Fix |
|---|---|---|---|
| Couldn't reach VM from host machine | `ssh-copy-id` failed to connect | VM network adapter was set to NAT (`10.0.2.15`), which isolates the VM from the host | Switched Adapter 1 to Bridged Adapter in VirtualBox settings; VM received a reachable address (`192.168.1.66`) on the home network |
| vi editor seemed unresponsive in insert mode | Couldn't tell if typing was registering | Unfamiliarity with vi's modal editing (normal vs insert mode) | Confirmed `-- INSERT --` appears in the status line before typing; used `Esc` then `:wq!`/`:q!` to save/quit |
| Page loaded but showed no content from the host browser | Blank page in browser, but curl worked on the VM | `/srv/website/index.html` was copied before the custom content was saved, or browser was showing a cached empty response | Verified file contents on the VM with `cat`, re-copied the edited file, and hard-refreshed the browser (private window) to rule out caching |
| Backup script failed with "No such file or directory" | `tar` errors referencing `/srv/backups/website-*.tar.gz` | `/srv/backups` directory hadn't been created before the first run | Created the missing directory with `mkdir -p /srv/backups` and re-ran the script |
| Backup pruning step errored on `ls` | `ls: cannot access '/srv/backups/website-*.tar.gz'` even with the directory present | Wildcard `*` was inside the quotes in the script, so bash treated it as a literal filename instead of expanding it | Moved the closing quote so only `"$BACKUP_DIR"` was quoted, leaving the glob outside the quotes to expand correctly |

## Lessons Learned

- **Networking fundamentals matter before anything else works.** The NAT vs Bridged Adapter issue in Phase 3 wasn't a Linux problem at all — it was a networking concept I hadn't fully internalised. No SSH, web, or backup step works if the VM isn't reachable in the first place.
- **Snapshots are not optional.** Losing progress to a VM crash with no snapshot was the most costly mistake in this project, purely from lost time. Snapshotting after every phase from Phase 6 onward made recovery trivial by comparison.
- **`bash -x` is one of the most useful debugging tools available.** The backup script's quoting bug (wildcard trapped inside quotes) was invisible by reading the script, but obvious the moment it was traced line by line.
- **SELinux denials are a feature, not a bug to work around.** It would have been faster to just disable SELinux in Phase 5, but deliberately triggering and correctly fixing a denial with `semanage`/`restorecon` was far more valuable to demonstrate than leaving it off.
- **A backup you haven't restored isn't a backup you can trust.** Testing a real restore in Phase 7, and testing the pruning logic with fake aged files, caught behaviour that running the script "successfully" a few times would never have revealed.
- **Documenting as you go is far easier than reconstructing afterward.** Writing each phase into the README immediately after finishing it, with real output and real errors, kept the project accurate instead of relying on memory at the end.

---

## Repository Structure

```
.
├── README.md
├── images/          # screenshots referenced in this README
├── scripts/         # backup and monitoring scripts
└── configs/         # sanitised config files (sshd_config, nginx.conf, etc.)
```
