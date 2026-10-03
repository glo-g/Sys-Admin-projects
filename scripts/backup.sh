#!/bin/bash
# Simple backup script for RockSolid server

BACKUP_DIR="/srv/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOGFILE="/var/log/rocksolid-backup.log"

echo "[$DATE] Starting backup..." >> "$LOGFILE"

tar -czf "$BACKUP_DIR/website-$DATE.tar.gz" /srv/website 2>> "$LOGFILE"
tar -czf "$BACKUP_DIR/data-$DATE.tar.gz" /srv/data 2>> "$LOGFILE"

# Keep only the last 7 backups of each type
ls -1t "$BACKUP_DIR"/website-*.tar.gz | tail -n +8 | xargs -r rm --
ls -1t "$BACKUP_DIR"/data-*.tar.gz | tail -n +8 | xargs -r rm --

echo "[$DATE] Backup completed." >> "$LOGFILE"