#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Regenerate RetroArch savestates/savefiles units screen
function regenRAunitsScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	# Delete old retroarch path units and generate new ones
	# Source the script in a subshell so it can exit without exiting this script
	(. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh" true)

	# Fix incompatible settings
	# @todo ArkOS-specific
	if [ $? = 65 ]; then
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--yesno \
				"Due to a bug in ArkOS, the following settings are incompatible with automatic syncing. Would you like to use the recommended settings?:\n
				savefiles_in_content_dir\n
				savestates_in_content_dir" \
			16 56 8

		if [ $? = 1 ]; then
			whiptail \
				--title "${ARKLONE[whiptailTitle]}" \
				--msgbox "No action has been taken. You may still use the manual sync feature for RetroArch savefiles/savestates, but you will not be able to automatically sync them until the incompatible settings in retroarch.cfg are resolved." \
			16 56 8

		# Change user's settings
		else
			(. "${ARKLONE[installDir]}/retroarch/scripts/set-recommended-settings.sh")
		fi
	fi
}

