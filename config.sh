#!/bin/bash
#############
# INSTALL DIR
#############
ARKLONE_DIR="/opt/arklone"

###########
# RETROARCH
###########
# All paths containing a retroarch.cfg
RETROARCHS=(\
	"${HOME}/.config/retroarch" \
	"${HOME}/.config/retroarch32"\
)
# Root directory where ROMs are stored
RETROARCH_CONTENT_ROOT="/roms"

########
# RCLONE
########
REMOTES=$(rclone listremotes | awk -F : '{print $1}')

#########
# ARKLONE
#########
WHIPTAIL_TITLE="arklone cloud sync utility"

# Array of all enabled Arklone systemd path units
AUTOSYNC=($(systemctl list-unit-files | awk '/arkloned/ && /enabled/ {print $1}'))

# File containing currently selected remote
REMOTE_CONF="${HOME}/.config/arklone/remote.conf"
# String containing contents of ${REMOTE_CONF}
REMOTE_CURRENT=$(awk '{print $1}' "${REMOTE_CONF}" 2>/dev/null)

# Change working directory to install directory
cd "${ARKLONE_DIR}"
