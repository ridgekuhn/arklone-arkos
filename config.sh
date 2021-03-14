#!/bin/bash
USER_CONFIG_DIR="/home/ark/.config"

RETROARCHS=(\
	"/home/ark/.config/retroarch" \
	"/home/ark/.config/retroarch32"\
)
RETROARCH_CONTENT_ROOT="/roms"

ARKLONE_DIR="/opt/arklone"

REMOTES=$(rclone listremotes | awk -F : '{print $1}')
REMOTE_CONF="${USER_CONFIG_DIR}/arklone/remote.conf"
REMOTE_CURRENT=$(awk '{print $1}' "${REMOTE_CONF}" 2>/dev/null)

AUTOSYNC=($(systemctl list-unit-files | awk '/arkloned/ && /enabled/ {print $1}'))
