#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

[ "$(type -t printMenu)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/scripts/functions/printMenu.sh"
[ "$(type -t getRootInstanceNames)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

[ "$(type -t alreadyRunningScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/alreadyRunningScreen.sh"
[ "$(type -t logScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/logScreen.sh"

# Manual sync savefiles/savestates dialog
function manualSyncSavesScreen() {
	local script="${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"
	local instances=($(getRootInstanceNames))

	# Build a list of local directories
	local localdirs=$(
		for instance in ${instances[@]}; do
			local filterString=""

			# Populate ${filterString} if filter names begin with "retroarch-"
			if grep "retroarch-" <<<"${instance##*@}" >/dev/null 2>&1; then
				# Get array of filters from instance name
				local filters=($(tr '|' '\n' <<<"${instance##*@}"))

				# Separate multiple filters with pipe | and remove "retroarch-" prefix
				if [ "${#filters[@]}" -gt 1 ]; then
					filterString="($(
						for filter in ${filters[@]}; do
							printf "${filter##retroarch-}|"
						done
					))"
				# Just remove "retroarch-" prefix
				else
					filterString="(${filters##retroarch-})"
				fi
			fi

			# Print localdir and filter
			# eg,
			# "/path/to/foo(savefile|savestate)"
			printf "${instance%@*@*}${filterString/%|)/)} "
		done
	)

	# Check if sync script is already running
	alreadyRunning "${script}"

	# Allow user to select a directory to sync
	# @todo Add a "sync all" option
	if [ $? = 0 ]; then
		local selection=$(whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--menu \
				"Choose a directory to sync with (${ARKLONE[remote]}):" \
				16 60 8 \
				$(printMenu "${localdirs}") \
			3>&1 1>&2 2>&3 \
		)

		if [ ! -z "${selection}" ]; then
			local instance=${instances[$selection]}
			IFS="@" read -r localdir remotedir filter <<< "${instance}"

			# Sync the local and remote directories
			# Source the script in a subshell so it can exit without exiting this script
			(. "${script}" "send" "${instance}") && (. "${script}" "receive" "${instance}")

			if [ $? = 0 ]; then
				whiptail \
					--title "${ARKLONE[whiptailTitle]}" \
					--msgbox \
						"${localdir} synced to ${ARKLONE[remote]}:${remotedir}. Log saved to ${ARKLONE[log]}." \
						16 56 8
			else
				whiptail \
					--title "${ARKLONE[whiptailTitle]}" \
					--yesno \
						"Update failed. Would you like to view the log?" \
						16 56

				if [ $? = 0 ]; then
					logScreen
				fi
			fi
		fi
	fi
}

