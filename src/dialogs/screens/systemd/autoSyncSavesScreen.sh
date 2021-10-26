#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

[[ "$(type -t rebootScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/rebootScreen.sh"
[[ "$(type -t setCloudScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/setCloudScreen.sh"

# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
    whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --infobox \
            "Please wait while we configure your settings..." \
            16 56 8

    # Enable or disable path units
    local enabledUnits=(${ARKLONE[enabledUnits]})

    if [[ "${#enabledUnits[@]}" = 0 ]]; then
        . "${ARKLONE[installDir]}/src/systemd/scripts/enable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
            | . "${ARKLONE[installDir]}/src/dialogs/gauges/systemd/enable-path-units.sh"

        # Make sure user has a remote selected
        if [[ -z "${ARKLONE[remote]}" ]]; then
            setCloudScreen
        fi

        # Let user choose to reboot now
        rebootScreen

    else
        . "${ARKLONE[installDir]}/src/systemd/scripts/disable-path-units.sh" 3>&1 1>/dev/null 2>&3 \
            | . "${ARKLONE[installDir]}/src/dialogs/gauges/systemd/disable-path-units.sh"
    fi

    # Reset ${ARKLONE[enabledUnits]}
    ARKLONE[enabledUnits]=$(getEnabledUnits)
}

