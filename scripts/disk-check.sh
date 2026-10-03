#!/bin/bash
# Disk space alert script for RockSolid server

THRESHOLD=80
LOGFILE="/var/log/rocksolid-diskcheck.log"

df -h --output=pcent,target | tail -n +2 | while read -r line; do
    usage=$(echo "$line" | awk '{print $1}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $2}')
    if [ "$usage" -ge "$THRESHOLD" ]; then
        echo "[$(date)] WARNING: $mount is at ${usage}% usage" >> "$LOGFILE"
    fi
done