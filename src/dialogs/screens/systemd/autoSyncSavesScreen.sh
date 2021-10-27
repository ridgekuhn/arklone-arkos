#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

[[ "$(type -t newReceiveSavesTimer)" = "function" ]] || source "${ARKLONE[installDir]}/src/systemd/scripts/functions/newReceiveSavesTimer.sh"
[[ "$(type -t rebootScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/rebootScreen.sh"
[[ "$(type -t setCloudScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/setCloudScreen.sh"

# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
    # Get enabled units
    local enabledUnits=(${ARKLONE[enabledUnits]})

    # Enable units
    if [[ "${#enabledUnits[@]}" = 0 ]]; then
        # Get user timer selection
        local selection=$(whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --menu "Choose interval to attempt to receive saves from ${ARKLONE[remote]} in the background." \
                16 60 8 \
                "0" "Only receive saves on boot" \
                "1" "Every 10 minutes" \
                "2" "Every 20 minutes" \
                "3" "Every 30 minutes" \
                "4" "Every 40 minutes" \
                "5" "Every 50 minutes" \
                "6" "Every 60 minutes" \
            3>&1 1>&2 2>&3 \
        )

        local timerSeconds=$(( $selection * 600 ))

        # Create timer unit
        newReceiveSavesTimer "${timerSeconds}"

        # Enable units
        . "${ARKLONE[installDir]}/src/systemd/scripts/enable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
            | . "${ARKLONE[installDir]}/src/dialogs/gauges/systemd/enable-path-units.sh"

        # Make sure user has a remote selected
        if [[ -z "${ARKLONE[remote]}" ]]; then
            setCloudScreen
        fi

        # Let user choose to reboot now
        rebootScreen

    # Disable units
    else
        . "${ARKLONE[installDir]}/src/systemd/scripts/disable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
            | . "${ARKLONE[installDir]}/src/dialogs/gauges/systemd/disable-path-units.sh"
    fi

    # Reset ${ARKLONE[enabledUnits]}
    ARKLONE[enabledUnits]=$(getEnabledUnits)
}

