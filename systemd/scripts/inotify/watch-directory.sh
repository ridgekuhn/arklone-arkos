#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Recursively watch a directory for close_write events
#
# Starts service unit associated with passed path unit
#
# @param $1 Path to path unit
#
# @param [$2] Optional list of REGEX patterns to pass to inotifywait

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

PATH_UNIT="${1}"
EXCLUDES=(${@:2})

PATH_CHANGED="$(cat "${PATH_UNIT}" | grep "PathChanged=" | cut -d '=' -f 2)"
SERVICE_UNIT="$(cat "${PATH_UNIT}" | grep "Unit=" | cut -d '=' -f 2)"
EXCLUDE_STRING=""

# Construct EXCLUDE_STRING
for exclude in ${EXCLUDES[@]}; do
	EXCLUDE_STRING+="--exclude \"${exclude}\" "
done

# @todo Confirm these presumptions:
# 	1. Using a while loop with inotifywait instead of passing the -m option
# 	should avoid calling systemctl on every single close_write event
# 	2. Starting the systemd service
#		instead of running send-and-receive-saves.sh directly
#		should avoid running multiple concurrent processes
while inotifywait -qq -r -e close_write ${EXCLUDE_STRING} "${PATH_CHANGED}"; do
	sudo systemctl start "${SERVICE_UNIT}"
done

