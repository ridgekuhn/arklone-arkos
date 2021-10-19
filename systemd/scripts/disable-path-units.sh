#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Disable all arklone systemd units
#
# To output progress percentage for passing to dialog gauge,
# @see dialogs/gauges/systemd/disable-path-units.sh
#
# @param [$1] Optionally keep arkloned-receive-saves-boot.service if true

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

KEEP_BOOT_SERVICE="${1}"

# Store list of enabled unit names in an array
ENABLED_UNITS=(${ARKLONE[enabledUnits]})

# Disable path units
for unit in ${ENABLED_UNITS[@]}; do
    # Keep the boot service enabled if called from
    # @see dialogs/boot-sync.sh
    if
        [ "${KEEP_BOOT_SERVICE}" = "true" ] \
        && [ "${unit}" = "arkloned-receive-saves-boot.service" ]
    then
        continue
    fi

    sudo systemctl stop "${unit}" 2>/dev/null
    sudo systemctl disable "${unit}"
done

