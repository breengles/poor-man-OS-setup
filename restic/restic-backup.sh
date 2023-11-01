#!/bin/bash
# Runs Restic backup on a schedule via cron, emails with status
# 1. add a cred file with your repo logins to /etc/restic/cred
# 2. 

LOG="/home/artem/.log/restic.log"

backup_disk="/media/artem/BREE_STOR"
export RESTIC_REPOSITORY="$backup_disk/restic-backups"
export RESTIC_PASSWORD_FILE="/home/artem/restic-password.txt"

### keep last # of days of snapshots
KEEPDAYS=30

log() { 
    echo -e "$(date "+%Y-%m-%d %H:%M:%S"): ${1}" | tee -a "$LOG"
}

echo -e "\n" | tee -a "$LOG"

if ! mountpoint -q $backup_disk; then
  log "$backup_disk is not mounted"
  exit 1
fi

log "starting backup.."
msg=$(restic --exclude=".git" --verbose backup projects Sync >> "$LOG" 2>&1)
if [ $? -eq 1 ]
then
    notify "[restic backup]\n${msg}"
    log "${msg}\n-----------------------------------------"
    exit 1
fi

msg=$(restic check >> "$LOG" 2>&1)
if [ $? -eq 1 ]
then
    notify "[restic check]\n${msg}"
    log "${msg}\n--------------------------------------"
    exit 1
fi


log "removing old snapshots.."
msg=$(restic forget --keep-daily ${KEEPDAYS} --prune)
if [ $? -eq 1 ]
then
    notify "[restic forget]\n${msg}"
    log "${msg}"
    exit 1
fi

log "end of run\n-----------------------------------------\n\n"
log "Snapshot complete, snapshots older than $KEEPDAYS days deleted."
