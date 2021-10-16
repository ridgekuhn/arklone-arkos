#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

[ "$(type -t rcloneRemoteCheckScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/rcloneRemoteCheckScreen.sh"
[ "$(type -t regenRAunitsScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/regenRAunitsScreen.sh"
[ "$(type -t setCloudScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/setCloudScreen.sh"

# First run dialog
function firstRunScreen() {
	# Check for rclone remotes
	rcloneRemoteCheckScreen

	if [ $? != 0 ]; then
		return 1
	fi

	# Set recommended RetroArch settings
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--yesno "Welcome to arklone!\nWould you like to automatically configure RetroArch to the recommended settings?" \
			16 56 8

	if [ $? = 0 ]; then
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--infobox \
				"Please wait while we configure your settings..." \
				16 56 8

		"${ARKLONE[installDir]}/retroarch/scripts/set-recommended-settings.sh"
	fi

	# Generate RetroArch systemd path units
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--msgbox "We will now install several components for syncing RetroArch savefiles/savestates. This process may take several minutes, depending on your configuration." \
			16 56 8

	regenRAunitsScreen

	setCloudScreen
}
