#!/bin/bash
# ArkOS Backup Settings to Cloud
# By ridgek
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/logger.sh"

###########
# PREFLIGHT
###########
# Use same log as "/opt/system/Advanced/Backup Settings.sh"
logger "${ARKLONE[backupDir]}/arkosbackup.log"

#####
# RUN
#####
printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Exit if no network routes configured
if [ -z "$(ip route)" ]; then
	echo "ERROR: No internet connection. Exiting..."
	exit 1
fi

# Run normal ArkOS settings backup script
echo "Backing up your ArkOS settings..."
bash "/opt/system/Advanced/Backup Settings.sh"

if [ $? != 0 ]; then
	printf "\nCould not create backup file! Exiting...\n"
	exit 1
else
	# Sync backup to cloud
	echo "Sending ArkOS backup to ${ARKLONE[remote]}"
	rclone copy "${ARKLONE[backupDir]}/" "${ARKLONE[remote]}:ArkOS/" -v --filter "+ arkosbackup*" --filter "- *"
fi

