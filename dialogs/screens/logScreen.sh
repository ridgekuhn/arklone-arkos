#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Show the arklone log
function logScreen() {
    if [ -f "${ARKLONE[log]}" ]; then
        whiptail \
            --textbox "${ARKLONE[log]}" \
            16 56 \
            --scrolltext

    else
        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --msgbox "Could not find log file! (${ARKLONE[log]})" \
            16 56 8
    fi
}

