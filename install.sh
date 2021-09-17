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
	sudo chown ark:ark "${RETROARCH_CONTENT_ROOT}/backup"
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
if [ ! -d "${USER_CONFIG_DIR}/rclone" ]; then
	sudo mkdir "${USER_CONFIG_DIR}/rclone"
fi
sudo chown -R ark:ark "${USER_CONFIG_DIR}/rclone"
sudo chmod -R 777 "${USER_CONFIG_DIR}/rclone"

# Link user-accessible rclone.conf so rclone can find it
ln -v -s "${RETROARCH_CONTENT_ROOT}/backup/rclone/rclone.conf" "${USER_CONFIG_DIR}/rclone/rclone.conf"

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
if [ ! -d "${USER_CONFIG_DIR}/arklone" ]; then
	sudo mkdir "${USER_CONFIG_DIR}/arklone"
fi
sudo chown -R ark:ark "${USER_CONFIG_DIR}/arklone"
sudo chmod -R a+r+w "${USER_CONFIG_DIR}/arklone"
