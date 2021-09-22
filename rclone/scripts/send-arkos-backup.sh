#!/bin/bash
# ArkOS Backup Settings to Cloud
# By ridgek
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t arkloneLogger)" = "function" ] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

# Use same log as "/opt/system/Advanced/Backup Settings.sh"
arkloneLogger "${ARKLONE[backupDir]}/arkosbackup.log"

# Exit if no network routes configured
if [ -z "$(ip route)" ]; then
	echo "ERROR: No internet connection. Exiting..."
	exit 1
fi

printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Run normal ArkOS settings backup script
echo "Backing up your ArkOS settings..."
. "/opt/system/Advanced/Backup Settings.sh"

if [ $? != 0 ]; then
	printf "\nCould not create backup file! Exiting...\n"
	exit 1
else
	# Sync backup to cloud
	echo "Sending ArkOS backup to ${ARKLONE[remote]}"
	rclone copy "${ARKLONE[backupDir]}/" "${ARKLONE[remote]}:ArkOS/" -v --filter "+ arkosbackup*" --filter "- *" --config "${ARKLONE[rcloneConf]}"
fi

