#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

[ "$(type -t printMenu)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/scripts/functions/printMenu.sh"
[ "$(type -t getRootInstanceNames)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

[ "$(type -t alreadyRunningScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/alreadyRunningScreen.sh"
[ "$(type -t logScreen)" = "function" ] || source "${ARKLONE[installDir]}/dialogs/screens/logScreen.sh"

#########
# HELPERS
#########
# Get list of directory names
#
# @param $1 List of path unit instance names
#
# @returns Prints a list of local directory names, and filters if applicable
function getDirList() {
	local instances=($@)

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
}

######
# MAIN
######
# Manual sync savefiles/savestates dialog
#
# @returns Exit code of rclone sync script
function manualSyncSavesScreen() {
	local instances=($(getRootInstanceNames))
	local localdirs=$(getDirList ${instances[@]})
	local exitCode=0

	# Get user's directory selection
	local dirSelection=$(whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--menu \
			"Choose a directory to sync with (${ARKLONE[remote]}):" \
			16 60 8 \
			"a" "Sync all" "" "" $(printMenu "${localdirs}") \
		3>&1 1>&2 2>&3 \
	)

	# Return if user canceled
	[ $dirSelection ] || return

	# Get user's sync method selection
	local syncMethod=$(whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--menu \
			"Would you like to send or receive?" \
			16 60 8 \
			0 "Send" 1 "Receive" \
		3>&1 1>&2 2>&3 \
	)

	# Return if user canceled
	if [ ! $syncMethod ]; then
		return

	# Else, set the sync method
	elif [ "${syncMethod}" = 0 ]; then
		syncMethod="send"
	else
		syncMethod="receive"
	fi

	# Sync all path units
	if [ "${dirSelection}" = "a" ]; then
		local script="${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh"

		# Check if sync script is already running
		alreadyRunningScreen "${script}"

		if [ $? = 0 ]; then
			# Source script, but run in subshell so it can exit without exiting this script
			(. "${script}" "${syncMethod}")

			exitCode=$?
		fi

	# Sync one path unit
	else
		local script="${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"

		# Check if sync script is already running
		alreadyRunningScreen "${script}"

		if [ $? = 0 ]; then
			# Get the selected instance name
			local instance=${instances[$dirSelection]}

			# Source the script in a subshell so it can exit without exiting this script
			(. "${script}" "${syncMethod}" "${instance}")

			exitCode=$?
		fi
	fi

	# Show log to user if sync failed
	if [ $exitCode != 0 ]; then
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--yesno \
				"Sync failed. Would you like to view the log?" \
				16 56

		if [ $? = 0 ]; then
			logScreen
		fi
	fi
}

