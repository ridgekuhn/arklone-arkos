#!/bin/bash
# arklone uninstallation script
# by ridgek
source "/opt/arklone/config.sh"

# Get list of installed units
UNITS=($(systemctl list-unit-files "arkloned*"))

# Remove units from systemd
if [ ! -z "${UNITS}" ]; then
	for unit in ${UNITS[@]}; do
		sudo systemctl disable "${unit}"
	done
fi

# If user already had rclone installed,
# restore rclone.conf to original state
if [ -f "${ARKLONE[userCfgDir]}/.rclone.lock" ]; then
	echo "Restoring your rclone settings..."

	cp "${ARKLONE[backupDir]}/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf.arklone$(date +%s).bak"
	mv "${ARKLONE[backupDir]}/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"
else
	sudo apt remove rclone -y
fi

# Remove user-accessible backup dir if it did not exist on install
if [ -f "${ARKLONE[userCfgDir]}/.backupDir.lock" ]; then
	rm -rf "${ARKLONE[backupDir]}"

# Else, only remove the directories created by arklone
else
	rm -rf "${ARKLONE[backupDir]}/rclone"
	rm -rf "${ARKLONE[backupDir]}/arklone"
fi

# Remove arklone user config dir
rm -rf "${ARKLONE[userCfgDir]}"

# Remove arklone
sudo rm -rf /opt/arklone

echo "Uninstallation complete. Thanks for trying arklone!"

