#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Store list of enabled unit names in an array
ENABLED_UNITS=(${ARKLONE[enabledUnits]})

# Disable path units
if [ "${#ENABLED_UNITS[@]}" -gt 0 ]; then
	for unit in ${ENABLED_UNITS[@]}; do
		sudo systemctl disable "${unit}"
	done
fi

