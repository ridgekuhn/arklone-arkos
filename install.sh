#!/bin/bash
# arklone installation script
# by ridgek
########
# CONFIG
########
source "/opt/arklone/config.sh"

##############
# DEPENDENCIES
##############
# Install rclone
if ! rclone --version &> /dev/null; then
	sudo apt update && sudo apt install rclone -y || (echo "Could not install required dependencies" && exit 1)
fi

# Create backup dir, from user setting in ${ARKLONE[userCfgDir]/arklone.cfg}
# ArkOS default is /roms/backup
# Should be somewhere easily-accessible for non-Linux users,
# like a FAT partition or samba share
if [ ! -d "${ARKLONE[backupDir]}" ]; then
	sudo mkdir "${ARKLONE[backupDir]}"
	sudo chown "${USER}":"${USER}" "${ARKLONE[backupDir]}"
fi

# Create user-accessible rclone dir in ${ARKLONE[backupDir]}
if [ ! -d "${ARKLONE[backupDir]}/rclone" ]; then
	sudo mkdir "${ARKLONE[backupDir]}/rclone"
fi

# Create user-accessible rclone.conf on ${RETROARCH_CONTENT_ROOT}
if [ ! -f "${ARKLONE[backupDir]}/rclone/rclone.conf" ]; then
	sudo touch "${ARKLONE[backupDir]}/rclone/rclone.conf"
fi

# Create rclone user config dir
if [ ! -d "${HOME}/.config/rclone" ]; then
	sudo mkdir "${HOME}/.config/rclone"
fi
sudo chown -R "${USER}":"${USER}" "${HOME}/.config/rclone"
sudo chmod -R 777 "${HOME}/.config/rclone"

# Link user-accessible rclone.conf so rclone can find it
ln -v -s "${ARKLONE[backupDir]}/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"

#########
# arklone
#########
# Grant permissions to scripts
sudo chmod -v a+r+x "${ARKLONE[installDir]}/uninstall.sh"
sudo chmod -v a+r+x "${ARKLONE[installDir]}/dialogs/settings.sh"
sudo chmod -v a+r+x "${ARKLONE[installDir]}/rclone/scripts/sync-saves.sh"
sudo chmod -v a+r+x "${ARKLONE[installDir]}/rclone/scripts/sync-saves-boot.sh"
sudo chmod -v a+r+x "${ARKLONE[installDir]}/rclone/scripts/sync-arkos-backup.sh"
sudo chmod -v a+r+x "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

# Create user-accessible rclone dir on ${RETROARCH_CONTENT_ROOT}
if [ ! -d "${ARKLONE[backupDir]}/arklone" ]; then
	sudo mkdir "${ARKLONE[backupDir]}/arklone"
fi

# Create arklone user config dir
if [ ! -d "${ARKLONE[userCfgDir]}" ]; then
	sudo mkdir "${ARKLONE[userCfgDir]}"
fi
sudo chown -R "${USER}":"${USER}" "${ARKLONE[userCfgDir]}"
sudo chmod -R a+r+w "${ARKLONE[userCfgDir]}"
cp "${ARKLONE[installDir]}/arklone.cfg.orig" "${ARKLONE[userCfgDir]}/arklone.cfg"
