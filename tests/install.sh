#!/bin/bash
source "/opt/arklone/config.sh"

# Configure lock file pre-requisites
if ! rclone --version &> /dev/null; then
	sudo apt update && sudo apt install rclone -y || (echo "Could not install required dependencies" && exit 1)
fi

[ -d "${ARKLONE[backupDir]}" ] || mkdir "${ARKLONE[backupDir]}"

# Run installer
"${ARKLONE[installDir]}/install.sh"

# User config directory exists
# eg, /home/user/.config/arklone
[ -d "${ARKLONE[userCfgDir]}" ] || exit 72

# User config file exists
[ -f "${ARKLONE[userCfg]}" ] || exit 72

# Backup dirs and lock exist
[ -d "${ARKLONE[backupDir]}" ] || exit 72
[ -f "${ARKLONE[userCfgDir]}/.backupDir.lock" ] || exit 72
[ -d "${ARKLONE[backupDir]}/arklone" ] || exit 72
[ -d "${ARKLONE[backupDir]}/rclone" ] || exit 72

# rclone lock exists
[ -f "${ARKLONE[userCfgDir]}/.rclone.lock" ] || exit 72

# rclone.conf exists
[ -f "${ARKLONE[backupDir]}/rclone/rclone.conf" ] || exit 72

if ! file "${HOME}/.config/rclone/rclone.conf" | grep "symbolic link to ${ARKLONE[backupDir]}/rclone/rclone.conf"; then
	exit 72
fi

# Check script executable permissions
SCRIPTS=($(find "${ARKLONE[installDir]}" -type f -name "*.sh"))

for script in ${SCRIPTS[@]}; do
	if ! ls -al "${script}" | grep -E '^-..x..x..x' >/dev/null; then
		exit 77
	fi
done

# systemd units directory is owned by user
if ! ls -al "${ARKLONE[installDir]}/systemd/units" | grep "${USER} ${USER}" >/dev/null; then
	exit 77
fi

# Done
echo "SUCCESS"
