#!/bin/bash
source "/opt/arklone/config.sh"

# Run uninstaller
"/opt/arklone/uninstall.sh"

# Check units were removed from systemd
if systemctl list-unit-files | grep -E '^arklone'; then
	exit 78
fi

# Original rclone.conf was restored
[ -f "${HOME}/.config/rclone/rclone.conf" ] || exit 72

if file "${HOME}/.config/rclone/rclone.conf" | grep "symbolic link"; then
	exit 78
fi

# Original backup directory exists
# @todo ArkOS-specific
[ -d "${ARKLONE[backupDir]}" ] || exit 72

# Backup dir does not contain arklone subdirs
# @todo ArkOS-specific
[ ! -d "${ARKLONE[backupDir]}/rclone" ] || exit 78
[ ! -d "${ARKLONE[backupDir]}/arklone" ] || exit 78

# arklone user config dir was removed
[ ! -d "${ARKLONE[userCfgDir]}" ] || exit 78

# arklone install dir was removed
[ ! -d "${ARKLONE[installDir]}" ] || exit 78

# Done
echo "SUCCESS"
