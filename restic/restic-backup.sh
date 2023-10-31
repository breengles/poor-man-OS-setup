#!/bin/bash
# Runs Restic backup on a schedule via (ana)cron
# put it in /etc/cron.daily

LOG="${HOME}/.log/restic.log"

export RESTIC_REPOSITORY="/path/to/repo"
export RESTIC_PASSWORD_FILE="/path/to/restic-password.txt"

### keep last # of days of snapshots
KEEPDAYS=30

log() { 
    echo -e "$(date "+%Y%m%d_%H%M%S"): ${1}" | tee -a "$LOG"
}

echo -e "\n" | tee -a "$LOG"

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
