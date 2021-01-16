#!/bin/bash
# ArkOS Backup Settings to Cloud
# By ridgek
########
# CONFIG
########
source "/opt/arklone/config.sh"

###########
# PREFLIGHT
###########
# Use same log as "/opt/system/Advanced/Backup Settings.sh"
LOG_FILE="/roms/backup/arkosbackup.log"

# Delete old log
if [ -f "${LOG_FILE}" ]; then
	rm -f "${LOG_FILE}"
fi

# Begin logging
if touch "${LOG_FILE}"; then
	exec &> >(tee -a "${LOG_FILE}")
else
	echo "Could not open log file. Exiting..."
	exit 1
fi

#####
# RUN
#####
printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Exit if no internet
if ! : >/dev/tcp/8.8.8.8/53; then
	echo "No internet connection. Exiting..."
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
	echo "Sending ArkOS backup to ${REMOTE_CURRENT}"
	rclone copy /roms/backup/ ${REMOTE_CURRENT}:ArkOS/ -v --filter "+ arkosbackup*" --filter "- *"
fi

