#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# enable-path-units.sh progress gauge dialog
#
# Converts output of systemd/scripts/enable-path-units.sh
# to progress percentage for passing to dialog gauge
#
# Since `systemctl enable` outputs success messages to stderr for some reason,
# redirect stderr to stdin before piping to this script.
#
# @usage
#		. "${ARKLONE[installDir]}/systemd/scripts/enable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
#			| . "${ARKLONE[installDir]}/dialogs/screens/gauges/enable-path-units.sh"

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

SERVICES=($(find "${ARKLONE[unitsDir]}/"*".service"))
PATH_UNITS=($(find "${ARKLONE[unitsDir]}/"*".path"))
TOTAL_UNITS=$(( ${#SERVICES[@]} + ${#PATH_UNITS[@]} ))

# Read from stdin and calculate progress percentage
while read line; do
	# Get the unit name that was just enabled
	unit="$(sed -e 's/Created symlink.*→ //' -e 's/\.$//' <<<"${line}")"

	# Process service units first like the corresponding script
	if grep ".service" <<<"${line}" >/dev/null 2>&1; then
		# Get the index of the services in ${SERVICES[@]}
		for i in "${!SERVICES[@]}"; do
			if [ "${SERVICES[$i]}" = "${unit}" ]; then
				# Convert index to a percentage of total units processed
				echo $(( ( $i * 100 ) / $TOTAL_UNITS ))
			fi
		done

	# Process path units
	elif grep ".path" <<<"${line}" >/dev/null 2>&1; then
		# Get the index of the path unit in ${PATH_UNITS[@]}
		for i in "${!PATH_UNITS[@]}"; do
			if [ "${PATH_UNITS[$i]}" = "${unit}" ]; then
				# Convert index to a percentage of total units processed
				echo $(( ( ( $i + ${#SERVICES[@]} ) * 100 ) / $TOTAL_UNITS ))
			fi
		done
	fi
done | whiptail \
	--title "${ARKLONE[whiptailTitle]}" \
	--gauge "Please wait while we enable automatic syncing..." \
	16 56 \
	0

