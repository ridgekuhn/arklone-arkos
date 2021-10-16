#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# disable-path-units.sh progress gauge dialog
#
# Converts output of systemd/scripts/disable-path-units.sh
# to progress percentage for passing to dialog gauge
#
# Since `systemctl enable` outputs success messages to stderr for some reason,
# redirect stderr to stdin before piping to this script.
#
# @usage
#		. "${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
#			| . "${ARKLONE[installDir]}/dialogs/screens/gauges/disable-path-units.sh"

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

ENABLED_UNITS=(${ARKLONE[enabledUnits]})
TOTAL_UNITS=${#ENABLED_UNITS[@]}

while read line; do
	if grep "system/arkloned" <<<"${line}" >/dev/null 2>&1; then
		unit="$(sed -e 's|Removed /etc/systemd/system/||' -e 's/\.$//' <<<"${line}")"

		# Get the index of the path unit in ${PATH_UNITS[@]}
		for i in "${!ENABLED_UNITS[@]}"; do
			if [ "${ENABLED_UNITS[$i]}" = "${unit}" ]; then
				# Convert index to a percentage of total units processed
				echo $(( ( $i * 100 ) / $TOTAL_UNITS ))
			fi
		done
	fi
done | whiptail \
	--title "${ARKLONE[whiptailTitle]}" \
	--gauge "Please wait while we disable automatic syncing..." \
	16 56 \
	0

