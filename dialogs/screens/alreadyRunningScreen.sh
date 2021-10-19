#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Check if script is already running
#
#	If script is already running, user is shown ${ARKLONE[log]}
#
# @param $1 {string} Path to script
#
# @returns 1 if $1 is an active process
function alreadyRunningScreen() {
    local script="${1}"

    local running=$(pgrep "${script##*/}")

    if [ ! -z "${running}" ]; then
        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --yesno \
                "${script##*/} is already running. Would you like to see the log file?" \
                16 60

        if [ $? = 0 ]; then
            whiptail \
                --title "${ARKLONE[log]}" \
                --scrolltext \
                --textbox \
                    "${ARKLONE[log]}" \
                    16 60
        fi

        return 1
    fi
}

