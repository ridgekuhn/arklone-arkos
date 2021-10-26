#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

# Check if rclone is configured
function rcloneRemoteCheckScreen() {
    if [[ -z "$(rclone listremotes 2>/dev/null)" ]]; then
        whiptail \
            --title "${ARKLONE[whiptailTitle]}" \
            --msgbox "It looks like you haven't configured any rclone remotes yet! Please see the documentation at:\nhttps://github.com/ridgekuhn/arklone-arkos\nand\nhttps://rclone.org/docs/" \
            16 56 8

        return 1
    fi
}

