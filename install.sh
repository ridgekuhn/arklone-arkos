#!/bin/bash
# arklone installation script
# by ridgek
source "/opt/arklone/config.sh"

############
# FILESYSTEM
############
# Create arklone user config dir
# eg,
# /home/user/.config/arklone
if [ ! -d "${ARKLONE[userCfgDir]}" ]; then
	mkdir "${ARKLONE[userCfgDir]}"
fi

# Copy default config to user config path
cp "${ARKLONE[installDir]}/arklone.cfg.orig" "${ARKLONE[userCfgDir]}/arklone.cfg"

# Create backup dir from user setting in ${ARKLONE[userCfg]}
# ArkOS default is /roms/backup
# Should be somewhere easily-accessible for non-Linux users,
# like a FAT partition or samba share
# @todo ArkOS specific
if [ ! -d "${ARKLONE[backupDir]}" ]; then
	mkdir "${ARKLONE[backupDir]}"
	chown "${USER}":"${USER}" "${ARKLONE[backupDir]}"

	# Create a lock file so we know if we can safely delete on uninstall
	touch "${ARKLONE[userCfgDir]}/.backupDir.lock"
fi

if [ ! -d "${ARKLONE[backupDir]}/arklone" ]; then
	mkdir "${ARKLONE[backupDir]}/arklone"
fi

if [ ! -d "${ARKLONE[backupDir]}/rclone" ]; then
	mkdir "${ARKLONE[backupDir]}/rclone"
fi

########
# RCLONE
########
# Install rclone
if ! rclone --version &> /dev/null; then
	sudo apt update && sudo apt install rclone -y || (echo "Could not install required dependencies" && exit 1)
else
	# Set a lock file so we can know to restore user's settings on uninstall
	touch "${ARKLONE[userCfgDir]}/.rclone.lock"

	# Backup user's rclone.conf and move it to ${ARKLONE[backupDir]}/rclone/
	if [ -f "${HOME}/.config/rclone/rclone.conf" ]; then
		cp "${HOME}/.config/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf.arklone$(date +%s).bak"
		mv "${HOME}/.config/rclone/rclone.conf" "${ARKLONE[backupDir]}/rclone/rclone.conf"
	fi
fi

# Create user-accessible rclone.conf in ${ARKLONE[backupDir]}
# and symlink it to the default rclone location
touch "${ARKLONE[backupDir]}/rclone/rclone.conf"
ln -v -s "${ARKLONE[backupDir]}/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"

#########
# ARKLONE
#########
# Make scripts executable
SCRIPTS=($(find /opt/arklone/ -type f -name "*.sh"))
for script in ${SCRIPTS[@]}; do
	sudo chmod a+x "${script}"
done

# Make systemd units directory writeable for user
sudo chown ${USER}:${USER} "${ARKLONE[installDir]/systemd/units}"

