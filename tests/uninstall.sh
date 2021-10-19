#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

# Test uninstaller
# @param $1 {boolean} Keep install dir if true
KEEP_INSTALL_DIR=$1

#####
# RUN
#####
# Run uninstaller
"${ARKLONE[installDir]}/uninstall.sh" $KEEP_INSTALL_DIR

########
# TEST 1
########
# Check units were removed from systemd
if systemctl list-unit-files | grep -E '^arklone'; then
    exit 78
fi

echo "TEST 1 passed."

########
# TEST 2
########
# Original rclone.conf was restored
[ -f "${HOME}/.config/rclone/rclone.conf" ] || exit 72

if file "${HOME}/.config/rclone/rclone.conf" | grep "symbolic link"; then
    exit 78
fi

echo "TEST 2 passed."

########
# TEST 3
########
# Original backup directory exists
# @todo ArkOS-specific
[ -d "${ARKLONE[backupDir]}" ] || exit 72

# Backup dir does not contain arklone subdirs
[ ! -d "${ARKLONE[backupDir]}/rclone" ] || exit 78
[ ! -d "${ARKLONE[backupDir]}/arklone" ] || exit 78

echo "TEST 3 passed."

########
# TEST 4
########
# arklone user config dir was removed
[ ! -d "${ARKLONE[userCfgDir]}" ] || exit 78

echo "TEST 4 passed."

########
# TEST 5
########
# arklone install dir was removed
if [ $KEEP_INSTALL_DIR ]; then
    [ -d "${ARKLONE[installDir]}" ] || exit 78
else
    [ ! -d "${ARKLONE[installDir]}" ] || exit 78
fi

echo "TEST 5 passed."

##########
# TEARDOWN
##########
echo "SUCCESS"

