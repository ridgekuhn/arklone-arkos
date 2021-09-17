#!/bin/bash
# arklone uninstallation script
# by ridgek
########
# CONFIG
########
source "./config.sh"

###########
# PREFLIGHT
###########
UNITS=($(systemctl list-unit-files | awk '/arkloned/ {print $1}'))

#########
# arklone
#########
# Remove units from systemd
if [ ! -z "${UNITS}" ]; then
	for unit in ${UNITS[@]}; do
		sudo systemctl disable "${unit}"
	done
fi

# Remove arklone user config dir
sudo rm -r "${HOME}/.config/arklone"

# Print confirmation
echo "======================================================================"
echo "arklone has been uninstalled, but some files must be deleted manually:"
echo "/opt/system/Cloud Settings.sh"
echo "/opt/arklone/"
echo "${HOME}/.config/rclone/"
echo "/roms/backup/rclone/rclone.conf"
