#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

whiptail --msgbox fuck 10 30
exit

chvt 2

echo arklone has ${#ARKLONE[@]}
echo "${ARKLONE[balls]}"

for ((i = 30; i > 0; i--)); do
    echo $i
    sleep 1
done
chvt 1
kill $(pidof oga_controls)
exit

# Dialog shown to user on boot
#
# Checks for dirty boot state, and configured network connection.
# If network is up, attempts to run
# @see rclone/scripts/receive-saves.sh
#
# @returns Exit code of receive-saves.sh
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t killOnKeyPress)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/killOnKeyPress.sh"

#############
# SUB SCREENS
#############
# Warn if sync failed on previous boot
function dirtyBootScreen() {
    whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --msgbox "WARNING: There was a problem receiving save data from the cloud during your last session. Please verify that your cloud copy is correct. Proceeding may overwrite data on your device if the cloud copy has a newer timestamp." \
        16 56 8
}

# Check for network config
#
# @returns 1 if no routes available
function networkCheckScreen() {
    # Check if ip reports configured router tables
    if [[ -z "$(ip route)" ]]; then
        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --yesno "No configured network devices detected. If you use a USB wifi dongle or ethernet cable, make sure it's plugged in and try again." \
            --yes-button "Try Again" \
            --no-button "Cancel" \
            16 56 8

        if [[ $? = 0 ]]; then
            networkCheckScreen
        else
            return 1
        fi
    fi
}

# Receive updates from cloud
function receiveSavesScreen() {
    whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --infobox "Attempting to receive new save data from the cloud.\nPress any key to abort at any time." \
        16 56 8

    killOnKeypress "${ARKLONE[installDir]}/src/rclone/scripts/receive-saves.sh"
}

# Allow user to try to sync again on error
function tryAgainScreen() {
    whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --yesno "There was a problem receiving save data from the cloud. Would you like to try again?" \
        --yes-button "Try Again" \
        --no-button "Cancel" \
        16 56 8
}

# Final error screen before exiting
function errorScreen() {
    whiptail \
        --title "${ARKLONE[whiptailTitle]}" \
        --msgbox "WARNING: Could not receive all save data updates from the cloud. To minimize potential data loss, automatic syncing will be stopped for this session. For more info, see the log file at:\n${ARKLONE[log]}" \
        16 56 8
}

#############
# MAIN SCREEN
#############
# Main screen
#
# @returns 0 if all cloud syncs are successful
function mainScreen() {
    local exitCode=0

    # Check for dirty boot
    if [[ -f "${arklone[dirtyBoot]}" ]]; then
        # Clean up dirty boot state before showing the whiptail to the user
        rm "${arklone[dirtyBoot]}"
        . "${ARKLONE[installDir]}/src/systemd/scripts/enable-path-units.sh"

        dirtyBootScreen
    fi

    # Check for network connection
    networkCheckScreen
    exitCode=$?

    # Receive cloud sync
    if [[ "${exitCode}" = 0 ]]; then
        receiveSavesScreen
        exitCode=$?
    fi

    # Try again if there were any errors
    if [[ "${exitCode}" != 0 ]]; then
        tryAgainScreen

        # Allow user to start over
        if [[ $? = 0 ]]; then
            mainScreen
            # Get recursion process return code
            # so it doesn't get overwritten by the current value
            exitCode=$?

        # Warn user of error, stop automatic sync, and set dirty boot lockfile
        else
            errorScreen

            # Set dirty boot state
            . "${ARKLONE[installDir]}/src/systemd/scripts/disable-path-units.sh"
            touch "${arklone[dirtyBoot]}"
        fi
    fi

    return $exitCode
}

#####
# RUN
#####
clear

mainScreen

clear

exit $?

