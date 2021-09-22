#!/bin/bash
source "/opt/arklone/functions/loadConfig.sh"

# Set default settings
declare -A ARKLONE
ARKLONE=(
	# Install Paths
	[installDir]="/opt/arklone"
	[userCfgDir]="${HOME}/.config/arklone"
	# [backupDir]="/roms/backup"

	# arklone config file
	[userCfg]="${ARKLONE[userCfgDir]}/arklone.cfg"

	# Dirty boot lock file
	# @todo @see
	[dirtyBoot]="${ARKLONE[userCfgDir]}/dirtyboot"

	# rclone
	# [rcloneConf]="/home/ark/.config/rclone/rclone.conf"
	# [remote]=""

	# Log
	# [log]="/dev/shm/arklone.log"

	# RetroArch
	# [retroarchContentRoot]="/roms"
	# [retroarchCfg]="/home/user/.config/retroarch/retroarch.cfg"

	# systemd
	[autoSync]=$(systemctl list-unit-files arkloned* | grep "enabled" | cut -d " " -f 1)

	# Whiptail settings
	[whiptailTitle]="arklone cloud sync utility"
)

# Load the user's config file
loadConfig "${ARKLONE[userCfg]}" ARKLONE

