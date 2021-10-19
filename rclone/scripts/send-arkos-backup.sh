#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Runs the ArkOS backup script and sends the archive to the cloud

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"
[[ "$(type -t arkloneLogger)" = "function" ]] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

# Find the ArkOS backup script
BACKUP_SCRIPT=""

if [[ -f "/opt/system/Advanced/Backup Settings.sh" ]]; then
    BACKUP_SCRIPT="/opt/system/Advanced/Backup Settings.sh"

elif [[ -f "/opt/system/Advanced/Backup ArkOS Settings.sh" ]]; then
    BACKUP_SCRIPT="/opt/system/Advanced/Backup ArkOS Settings.sh"

else
    echo "ERROR: Could not find ArkOS backup script!"
    exit 1
fi

# Run normal ArkOS settings backup script
echo "Backing up your ArkOS settings..."
"${BACKUP_SCRIPT}"

if [[ $? != 0 ]]; then
    printf "\nCould not create backup file! Exiting...\n"
    exit 1
fi

# Exit if no network routes configured
if [[ -z "$(ip route)" ]]; then
    echo "ERROR: No internet connection. Exiting..."
    exit 1
fi

# Use same log as ArkOS backup Script
arkloneLogger "/roms/backup/arkosbackup.log"

printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Sync backup to cloud
echo "Sending ArkOS backup to ${ARKLONE[remote]}"

rclone copy "${ARKLONE[backupDir]}/" "${ARKLONE[remote]}:arklone/ArkOS/" -v --filter "+ arkosbackup*" --filter "- *" --config "${ARKLONE[rcloneConf]}"

