#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Configure lock file pre-requisites
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

[ -d "${ARKLONE[backupDir]}" ] || mkdir "${ARKLONE[backupDir]}"

#####
# RUN
#####
"${ARKLONE[installDir]}/install.sh"

########
# TEST 1
########
# User config directory exists
# eg, /home/user/.config/arklone
[ -d "${ARKLONE[userCfgDir]}" ] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# User config file exists
[ -f "${ARKLONE[userCfg]}" ] || exit 72

echo "TEST 2 passed."

########
# TEST 3
########
# Backup dirs and lock exist
[ -d "${ARKLONE[backupDir]}" ] || exit 72
[ -f "${ARKLONE[userCfgDir]}/.backupDir.lock" ] || exit 72
[ -d "${ARKLONE[backupDir]}/arklone" ] || exit 72
[ -d "${ARKLONE[backupDir]}/rclone" ] || exit 72

echo "TEST 3 passed."

########
# TEST 4
########
# rclone lock exists
[ -f "${ARKLONE[userCfgDir]}/.rclone.lock" ] || exit 72

echo "TEST 4 passed."

########
# TEST 5
########
# rclone.conf exists
[ -f "${ARKLONE[backupDir]}/rclone/rclone.conf" ] || exit 72

if ! file "${HOME}/.config/rclone/rclone.conf" | grep "symbolic link to ${ARKLONE[backupDir]}/rclone/rclone.conf"; then
	exit 72
fi

echo "TEST 5 passed."

########
# TEST 6
########
# inotifywait exists
if ! inotifywait --help >/dev/null 2>&1; then
	exit 72
fi

echo "TEST 6 passed."

########
# TEST 7
########
# Check script executable permissions
SCRIPTS=($(find "${ARKLONE[installDir]}" -type f -name "*.sh"))

for script in ${SCRIPTS[@]}; do
	if ! ls -al "${script}" | grep -E '^-..x..x..x' >/dev/null; then
		exit 77
	fi
done

echo "TEST 7 passed."

########
# TEST 8
########
# systemd units directory is owned by user
if ! ls -al "${ARKLONE[installDir]}/systemd/units" | grep "${USER} ${USER}" >/dev/null; then
	exit 77
fi

echo "TEST 8 passed."

