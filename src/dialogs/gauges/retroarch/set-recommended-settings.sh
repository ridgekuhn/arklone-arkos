#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# set-recommended-settings.sh progress gauge dialog
#
# Converts output of retroarch/scripts/set-recommended-settings.sh
# to progress percentage for passing to dialog gauge
#
# @usage
#		. "${ARKLONE[installDir]}/src/systemd/scripts/disable-path-units.sh" \
#			| . "${ARKLONE[installDir]}/src/dialogs/screens/gauges/disable-path-units.sh"

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

# Get array of all retroarch.cfg instances
RETROARCHS=(${ARKLONE[retroarchCfg]})

while read line; do
    if grep -E "retroarch.cfg$" <<<"${line}" >/dev/null; then
        retroarchCfg=$(sed -e 's|Now editing ||' <<<"${line}")

        # Get the index of the retroarch.cfg in ${RETROARCHS[@]}
        for i in "${!RETROARCHS[@]}"; do
            if [[ "${RETROARCHS[$i]}" = "${retroarchCfg}" ]]; then
                # Convert index to a percentage of total retroarch.cfgs processed
                echo $(( ( $i * 100 ) / ${#RETROARCHS[@]} ))
            fi
        done
    fi
done | whiptail \
    --title "${ARKLONE[whiptailTitle]}" \
    --gauge "Please wait while we configure your RetroArch settings..." \
    16 56 \
    0

