#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Reboot screen
function rebootScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--yesno \
			"You will need to reboot for the settings to take effect." \
			16 56 \
		--yes-button "Reboot Now" \
		--no-button "Later"

		if [ $? = 0 ]; then
			sudo reboot
		fi
}

