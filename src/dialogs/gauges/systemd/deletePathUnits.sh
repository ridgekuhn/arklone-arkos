#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

OLD_UNITS=($(find "${ARKLONE[unitsDir]}/arkloned-retroarch"*".auto.path" 2>/dev/null))

while read line; do
    if grep -E "^removed '/opt/arklone/src/systemd/units/arkloned-retroarch-.*.auto.path" <<<"${line}" >/dev/null 2>&1; then
        unit=$(sed -e "s|^removed '||" -e "s/'$//" <<<"${line}")

        for i in "${!OLD_UNITS[@]}"; do
            if [[ "${OLD_UNITS[$i]}" = "${unit}" ]]; then
                echo $(( ( $i * 100 ) / ${#OLD_UNITS[@]} ))
            fi
        done
    fi
done | whiptail \
    --title "${ARKLONE[whiptailTitle]}" \
    --gauge "Cleaning up old path units..." \
    16 56 \
    0
