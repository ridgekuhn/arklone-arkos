#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"

[[ "$(type -t alreadyRunningScreen)" = "function" ]] || source "${ARKLONE[installDir]}/dialogs/screens/alreadyRunningScreen.sh"
[[ "$(type -t logScreen)" = "function" ]] || source "${ARKLONE[installDir]}/dialogs/screens/logScreen.sh"

# Manual backup ArkOS settings screen
function manualBackupArkOSScreen() {
    local script="${ARKLONE[installDir]}/rclone/scripts/send-arkos-backup.sh"

    alreadyRunningScreen "${script}"

    if [[ $? = 0 ]]; then
        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --yesno \
                "This will create a backup of your settings at ${ARKLONE[backupDir]}/arkosbackup.tar.gz. Do you want to keep this file after it is uploaded to ${ARKLONE[remote]}?" \
                16 56

        # Store whether user wanted to keep the arkosbackup.tar.gz or not
        local keep=$?

        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --infobox \
                "Please wait while we back up your settings..." \
                16 56 8

        (. "${ARKLONE[installDir]}/rclone/scripts/send-arkos-backup.sh")

        # Backup was sent successfully
        if [[ $? = 0 ]]; then
            whiptail \
                --title "${ARKLONE[whiptailTitle]}" \
                --msgbox \
                    "ArkOS backup synced to ${ARKLONE[remote]}:ArkOS. Log saved to ${ARKLONE[backupDir]}/arkosbackup.log." \
                    16 56 8

            # Delete ArkOS settings backup file
            if [[ $keep != 0 ]]; then
                sudo rm -v "${ARKLONE[backupDir]}/arkosbackup.tar.gz"
            fi

        # Backup was not sent successfully
        else
            whiptail \
                --title "${ARKLONE[whiptailTitle]}" \
                --msgbox \
                    "Update failed. Would you like to view the log?." \
                    16 56 8

            if [[ $? = 0 ]]; then
                logScreen
            fi
        fi
    fi
}

