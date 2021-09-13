#!/bin/bash

########
# SYSTEM
########
USER_CONFIG_DIR="/home/ark/.config"

###########
# RETROARCH
###########
# All paths containing a retroarch.cfg
RETROARCHS=(\
	"${USER_CONFIG_DIR}/retroarch" \
	"${USER_CONFIG_DIR}/retroarch32"\
)
# @todo Get this from first retroarch.cfg above
RETROARCH_CONTENT_ROOT="/roms"

########
# RCLONE
########
REMOTES=$(rclone listremotes | awk -F : '{print $1}')

#########
# ARKLONE
#########
ARKLONE_DIR="/opt/arklone"
WHIPTAIL_TITLE="arklone cloud sync utility"

# Array of all enabled Arklone systemd path units
AUTOSYNC=($(systemctl list-unit-files | awk '/arkloned/ && /enabled/ {print $1}'))

# File containing currently selected remote
REMOTE_CONF="${USER_CONFIG_DIR}/arklone/remote.conf"
# String containing contents of ${REMOTE_CONF}
REMOTE_CURRENT=$(awk '{print $1}' "${REMOTE_CONF}" 2>/dev/null)
