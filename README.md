# Secure Multi-Service Server Build (Rocky Linux)

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
| Operating system | Rocky Linux (version: _fill in_) |
| Hypervisor | _e.g. VirtualBox / VMware / KVM_ |
| vCPUs / RAM | _fill in_ |
| Disks | Primary disk (_size_), secondary disk for LVM (_size, added later_) |
| Network mode | _e.g. Bridged / NAT / Host-only_ |
| Host machine | _e.g. Windows 11 / macOS / Linux_ |

**Confirm the OS version:**

```bash
cat /etc/os-release
hostnamectl
```

> **📸 Screenshot 1:** Output of `cat /etc/os-release` and `hostnamectl`
>
> Save as `images/01-os-version.png`

![OS version and hostname](images/01-os-version.png)

> **📸 Screenshot 2:** Your hypervisor window showing the VM settings (CPU, RAM, disks, network)
>
> Save as `images/02-vm-settings.png`

![VM settings](images/02-vm-settings.png)

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
- [ ] **Phase 7: Backup automation** (R9)
- [ ] **Phase 8: Monitoring and logging** (R10)
- [ ] **Phase 9: Final review and (optional) Ansible automation** (R11)

## Build Log

Each phase will be added below as it is completed, using this format:

> ### Phase N: Title
> - **Goal:** what this phase achieves and which requirement it meets
> - **Steps:** commands run, with a short explanation of each
> - **Verification:** how I proved it worked
> - **Screenshots:** evidence of the result

_Phase 1 onwards to be added._

## Troubleshooting Log

A record of real problems hit during the build and how they were fixed.

| Problem | Symptom | Cause | Fix |
|---|---|---|---|
| _to be added_ | | | |

## Lessons Learned

_To be completed at the end of the project._

---

## Repository Structure

```
.
├── README.md
├── images/          # screenshots referenced in this README
├── scripts/         # backup and monitoring scripts
└── configs/         # sanitised config files (sshd_config, nginx.conf, etc.)
```

> **Note:** Never upload private keys, passwords or real IP addresses. Sanitise config files and blur sensitive details in screenshots.
