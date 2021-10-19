#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

echo "Now installing arklone cloud sync utility..."

############
# FILESYSTEM
############
# Create arklone user config dir
# eg,
# /home/user/.config/arklone
if [[ ! -d "${ARKLONE[userCfgDir]}" ]]; then
    mkdir "${ARKLONE[userCfgDir]}"
fi

# Create backup dir from user setting in ${ARKLONE[userCfg]}
# Should be somewhere easily-accessible for non-Linux users,
# like a FAT partition or samba share
# ArkOS default is /roms/backup
# @todo ArkOS specific
if [[ ! -d "${ARKLONE[backupDir]}" ]]; then
    mkdir "${ARKLONE[backupDir]}"
    chown "${USER}":"${USER}" "${ARKLONE[backupDir]}"

# Create a lock file so we know not to delete on uninstall
else
    touch "${ARKLONE[userCfgDir]}/.backupDir.lock"
fi

if [[ ! -d "${ARKLONE[backupDir]}/arklone" ]]; then
    mkdir "${ARKLONE[backupDir]}/arklone"
fi

if [[ ! -d "${ARKLONE[backupDir]}/rclone" ]]; then
    mkdir "${ARKLONE[backupDir]}/rclone"
fi

########
# RCLONE
########
# Get the system architecture
SYS_ARCH=$(uname -m)

case $SYS_ARCH in
    aarch64 | arm64)
        SYS_ARCH="arm64"
    ;;
    x86_64)
        SYS_ARCH="amd64"
    ;;
esac

#Get the rclone download URL
RCLONE_PKG="rclone-current-linux-${SYS_ARCH}.deb"
RCLONE_URL="https://downloads.rclone.org/${RCLONE_PKG}"

# Check if user already has rclone installed
if rclone --version >/dev/null 2>&1; then
    # Set a lock file so we can know to restore user's settings on uninstall
    touch "${ARKLONE[userCfgDir]}/.rclone.lock"
fi

# Upgrade the user to the latest rclone
wget "${RCLONE_URL}" -O "${RCLONE_PKG}" \
    && sudo dpkg --force-overwrite -i "${RCLONE_PKG}"

rm "${RCLONE_PKG}"

# Make rclone config directory if it doesn't exit
if [[ ! -d "${HOME}/.config/rclone" ]]; then
    mkdir "${HOME}/.config/rclone"
fi

# Backup user's rclone.conf and move it to ${ARKLONE[backupDir]}/rclone/
# @todo ArkOS-specific
if [[ -f "${HOME}/.config/rclone/rclone.conf" ]]; then
    echo "Backing up and moving your rclone.conf to EASYROMS"

    cp "${HOME}/.config/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf.arklone$(date +%s).bak"

    # Suppress errors
    mv "${HOME}/.config/rclone/rclone.conf" "${ARKLONE[backupDir]}/rclone/rclone.conf" 2>/dev/null
fi

# Create user-accessible rclone.conf in ${ARKLONE[backupDir]}
# and symlink it to the default rclone location
touch "${ARKLONE[backupDir]}/rclone/rclone.conf"
ln -v -s "${ARKLONE[backupDir]}/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"

###############
# INOTIFY-TOOLS
###############
# Check if user already has inotify-tools installed
if inotifywait --help >/dev/null 2>&1; then
    # Set a lock file so we can know to not remove on uninstall
    touch "${ARKLONE[userCfgDir]}/.inotify-tools.lock"
else
    # Install inotify-tools
    sudo apt update && sudo apt install inotify-tools -y
fi

#########
# ARKLONE
#########
# Make scripts executable
SCRIPTS=($(find "${ARKLONE[installDir]}" -type f -name "*.sh"))
for script in ${SCRIPTS[@]}; do
    sudo chmod a+x "${script}"
done

# Make systemd units directory writeable for user
sudo chown ${USER}:${USER} "${ARKLONE[installDir]/systemd/units}"

