#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Disable all arklone systemd units
#
# @param [$1] Optionally keep arkloned-receive-saves-boot.service if true

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

KEEP_BOOT_SERVICE="${1}"

# Store list of enabled unit names in an array
ENABLED_UNITS=(${ARKLONE[enabledUnits]})

# Disable path units
if [ "${#ENABLED_UNITS[@]}" -gt 0 ]; then
	for unit in ${ENABLED_UNITS[@]}; do
		# Keep the boot service,
		# @see dialogs/boot-sync.sh
		if
			[ "${KEEP_BOOT_SERVICE}" = "true" ] \
			&& [ "${unit}" = "arkloned-receive-saves-boot.service" ]
		then
			continue
		fi

		sudo systemctl stop "${unit}"
		sudo systemctl disable "${unit}"
	done
fi

