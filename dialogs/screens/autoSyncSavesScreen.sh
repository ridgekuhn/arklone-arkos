#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

[ "$(type -t rebootScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/rebootScreen.sh"
[ "$(type -t setCloudScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/setCloudScreen.sh"

# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	# Enable or disable path units
	local enabledUnits=(${ARKLONE[enabledUnits]})

	if [ "${#enabledUnits[@]}" = 0 ]; then
		. "${ARKLONE[installDir]}/systemd/scripts/enable-path-units.sh"

		# Make sure user has a remote selected
		if [ -z "${ARKLONE[remote]}" ]; then
			setCloudScreen
		fi

		# Let user choose to reboot now
		rebootScreen

	else
		. "${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh"
	fi

	# Reset ${ARKLONE[enabledUnits]}
	ARKLONE[enabledUnits]=$(getEnabledUnits)
}

