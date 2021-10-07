#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ "$(type -t loadConfig)" = "function" ] || source "/opt/arklone/functions/loadConfig.sh"
[ "$(type -t getEnabledUnits)" = "function" ] || source "/opt/arklone/systemd/scripts/functions/getEnabledUnits.sh"

# Set default settings
declare -A ARKLONE
ARKLONE=(
	[installDir]="/opt/arklone"
	[userCfgDir]="${HOME}/.config/arklone"
	# @todo ArkOS-specific
	# [backupDir]="/roms/backup"

	# arklone config file
	[userCfg]="${ARKLONE[userCfgDir]}/arklone.cfg"

	# Dirty boot lock file
	[dirtyBoot]="${ARKLONE[userCfgDir]}/.dirtyboot"

	# rclone
	# @todo ArkOS-specific
	# [rcloneConf]="/home/ark/.config/rclone/rclone.conf"
	# [remote]=""
	[filterDir]="${ARKLONE[installDir]}/rclone/filters"

	# Log
	# [log]="/dev/shm/arklone.log"

	# RetroArch
	# @todo ArkOS-specific
	# [retroarchContentRoot]="/roms"
	# [retroarchCfg]="/home/user/.config/retroarch/retroarch.cfg"

	# systemd
	[enabledUnits]="$(getEnabledUnits)"
	[unitsDir]="${ARKLONE[installDir]}/systemd/units"
	[ignoreDir]="${ARKLONE[installDir]}/systemd/scripts/ignores"

	# Whiptail settings
	[whiptailTitle]="arklone cloud sync utility"
)

# Recreate userCfg if missing
if [ ! -f "${ARKLONE[userCfg]}" ]; then
	# Create userCfgDir if missing
	[ -d "${ARKLONE[userCfgDir]}" ] || mkdir "${ARKLONE[userCfgDir]}"

	# Copy userCfg back to default path
	# @todo Should we symlink this to ${ARKLONE[backupDir]} for ArkOS users?
	cp "${ARKLONE[installDir]}/arklone.cfg.orig" "${ARKLONE[userCfg]}"
fi

# Load the user's config file
loadConfig "${ARKLONE[userCfg]}" ARKLONE

