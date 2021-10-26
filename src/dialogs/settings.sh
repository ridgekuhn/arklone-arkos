#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

[[ "$(type -t firstRunScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/firstRunScreen.sh"
[[ "$(type -t setCloudScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/setCloudScreen.sh"
[[ "$(type -t logScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/logScreen.sh"
[[ "$(type -t manualBackupArkOSScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/rclone/manualBackupArkOSScreen.sh"
[[ "$(type -t manualSyncSavesScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/rclone/manualSyncSavesScreen.sh"
[[ "$(type -t autoSyncSavesScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/systemd/autoSyncSavesScreen.sh"
[[ "$(type -t regenRAunitsScreen)" = "function" ]] || source "${ARKLONE[installDir]}/src/dialogs/screens/systemd/regenRAunitsScreen.sh"

#############
# MAIN SCREEN
#############
# Point-of-entry dialog
function homeScreen() {
    # Set automatic sync mode string
    local ableString=$([[ "${ARKLONE[enabledUnits]}" ]] && echo "Disable" || echo "Enable")

    local selection=$(whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --menu "Choose an option:" \
            16 60 8 \
            "1" "Set cloud remote (now: $([[ "${ARKLONE[remote]}" ]] && echo "${ARKLONE[remote]}" || echo "NONE"))" \
            "2" "Manually sync saves" \
            "3" "${ableString} automatic saves sync" \
            "4" "Manual backup/sync ArkOS Settings" \
            "5" "Regenerate RetroArch path units" \
            "6" "View log file" \
        --cancel-button "Exit" \
        3>&1 1>&2 2>&3 \
    )

    # Send user to selected screen
    case $selection in
        1) setCloudScreen ;;
        2) manualSyncSavesScreen ;;
        3) autoSyncSavesScreen ;;
        4) manualBackupArkOSScreen ;;
        5) regenRAunitsScreen ;;
        6) logScreen ;;
        *) exit ;;
    esac

    # Recurse
    homeScreen
}

#####
# RUN
#####
# If ${ARKLONE[remote]} doesn't exist, assume this is the user's first run
if [[ -z "${ARKLONE[remote]}" ]]; then
    firstRunScreen

    if [[ $? != 0 ]]; then
        exit 1
    fi
fi

homeScreen

clear

