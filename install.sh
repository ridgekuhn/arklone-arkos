#!/bin/bash
# arklone installation script
# by ridgek
########
# CONFIG
########
source "./config.sh"

##############
# DEPENDENCIES
##############
# Install rclone
if ! rclone --version &> /dev/null; then
	sudo apt update && sudo apt install rclone -y || (echo "Could not install required dependencies" && exit 1)
fi

# Create backup dir in ${RETROARCH_CONTENT_ROOT}
if [ ! -d "${RETROARCH_CONTENT_ROOT}/backup" ]; then
	sudo mkdir "${RETROARCH_CONTENT_ROOT}/backup"
	sudo chown "${USER}":"${USER}" "${RETROARCH_CONTENT_ROOT}/backup"
fi

# Create user-accessible rclone dir on ${RETROARCH_CONTENT_ROOT}
if [ ! -d "${RETROARCH_CONTENT_ROOT}/backup/rclone" ]; then
	sudo mkdir "${RETROARCH_CONTENT_ROOT}/backup/rclone"
fi

# Create user-accessible rclone.conf on ${RETROARCH_CONTENT_ROOT}
if [ ! -f "${RETROARCH_CONTENT_ROOT}/backup/rclone/rclone.conf" ]; then
	sudo touch "${RETROARCH_CONTENT_ROOT}/backup/rclone/rclone.conf"
fi

# Create rclone user config dir
if [ ! -d "${HOME}/.config/rclone" ]; then
	sudo mkdir "${HOME}/.config/rclone"
fi
sudo chown -R "${USER}":"${USER}" "${HOME}/.config/rclone"
sudo chmod -R 777 "${HOME}/.config/rclone"

# Link user-accessible rclone.conf so rclone can find it
ln -v -s "${RETROARCH_CONTENT_ROOT}/backup/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"

#########
# arklone
#########
# Grant permissions to scripts
sudo chmod -v a+r+x "${ARKLONE_DIR}/uninstall.sh"
sudo chmod -v a+r+x "${ARKLONE_DIR}/dialogs/settings.sh"
sudo chmod -v a+r+x "${ARKLONE_DIR}/rclone/scripts/sync-saves.sh"
sudo chmod -v a+r+x "${ARKLONE_DIR}/rclone/scripts/sync-saves-boot.sh"
sudo chmod -v a+r+x "${ARKLONE_DIR}/rclone/scripts/sync-arkos-backup.sh"
sudo chmod -v a+r+x "${ARKLONE_DIR}/systemd/scripts/generate-retroarch-units.sh"

# Create user-accessible rclone dir on ${RETROARCH_CONTENT_ROOT}
if [ ! -d "${RETROARCH_CONTENT_ROOT}/backup/arklone" ]; then
	sudo mkdir "${RETROARCH_CONTENT_ROOT}/backup/arklone"
fi

# Create arklone user config dir
if [ ! -d "${HOME}/.config/arklone" ]; then
	sudo mkdir "${HOME}/.config/arklone"
fi
sudo chown -R "${USER}":"${USER}" "${HOME}/.config/arklone"
sudo chmod -R a+r+w "${HOME}/.config/arklone"
