#!/bin/bash
# arklone cloud sync on boot
# by ridgek
########
# CONFIG
########
source "./config.sh"
LOG_FILE="${RETROARCH_CONTENT_ROOT}/backup/arklone/arklone-saves.log"
DIRTY_BOOT="${USER_CONFIG_DIR}/arklone/dirtyboot"

#############
# CONTROLLERS
#############
source "${ARKLONE_DIR}/rclone/scripts/helpers/logger.sh"
source "${ARKLONE_DIR}/systemd/scripts/helpers/getRootInstanceNames.sh"

# Receive new save data from the cloud
#
# Only receives data and does not send anything back,
# to ensure that the cloud copy is the canonical version.
#
# Syncs "root" path unit instances only, since *.sub.auto.path units
# only exist because systemd path units can't watch subdirectories.
#
# @see systemd/scripts/helpers/getRootInstanceNames.sh
# @see systemd/scripts/generate-retroarch-units.sh
#
# @returns rclone exit code
function receiveCloudUpdates() {
	local instances=($(getRootInstanceNames))
	local exitCode=0

	logger "${LOG_FILE}"

	for instance in ${instances[@]}; do
		# Read paths from instance name
		local localdir remote dir filter
		IFS="@" read -r localdir remotedir filter <<< "${instance}"

		# Set global filter file
		local filterstring="--filter-from ${ARKLONE_DIR}/rclone/filters/global.filter"

		# Append unit-specific filter file (if specified in the instance name)
		if [ ! -z "${filter}" ]; then
			filterstring="${filterstring} --filter-from ${ARKLONE_DIR}/rclone/filters/${filter}.filter"
		fi

		local rcloneExitCode=0

		printf "\n======================================================\n"
		echo "Started new cloud sync at $(date)"
		echo "------------------------------------------------------"

		echo "Receiving ${REMOTE_CURRENT}:${remotedir}/ to ${localdir}/"
		rclone copy "${REMOTE_CURRENT}:${remotedir}/" "${localdir}/" ${filterstring} -u -v

		rcloneExitCode=$?

		# Record non-zero exit code if any instance fails to sync
		if [ "${rcloneExitCode}" != 0 ]; then
			exitCode="${rcloneExitCode}"
		fi
	done

	return $exitCode
}

# Run a script and kill it on user keypress
#
# @param $1 {number} The script to run
#
# @returns Exit/return code of script $1
function killOnKeypress() {
	local script=${1}

	# Run the script in the background
	$script &

	# Get the process id of $script
	local pid=$!

	# Monitor $script and listen for keypress in foreground
	while kill -0 "${pid}" >/dev/null 2>&1; do
		# If key pressed, kill $script and return with code 1
		read -sr -n 1 -t 1 && kill "${pid}" && return 1
	done

	# Set $? to return code of $script
	wait $pid

	# Return $script's exit code
	return $?
}

# Stop auto-syncing for this session
#
# @see config.sh
function stopPathUnits() {
	for pathUnit in ${AUTOSYNC[@]}; do
		sudo systemctl stop "${pathUnit}"
	done
}

#######
# VIEWS
#######
# Show warning if sync failed on previous boot
function dirtyBootScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--msgbox "WARNING: There was a problem receiving save data from the cloud during your last session. Please verify that your cloud copy is correct. Proceeding may overwrite data on your device if the cloud copy has a newer timestamp." \
		16 56 8
}

# Check for network config
#
# @returns 1 if no routes available
function networkCheckScreen() {
	# Check if ip reports configured router tables
	if [ -z "$(ip route)" ]; then
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--yesno "No configured network devices detected. If you use a USB wifi dongle or ethernet cable, make sure it's plugged in and try again." \
			--yes-button "Try Again" \
			--no-button "Cancel" \
			16 56 8

		if [ $? = 0 ]; then
			networkCheckScreen
		else
			return 1
		fi
	fi
}

# Receive updates from cloud
function receiveCloudUpdatesScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--infobox "Attempting to receive new save data from the cloud.\nPress any key to abort at any time." \
		16 56 8

	killOnKeypress receiveCloudUpdates
}

# Allow user to try to sync again on error
function tryAgainScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--yesno "There was a problem receiving save data from the cloud. Would you like to try again?" \
		--yes-button "Try Again" \
		--no-button "Cancel" \
		16 56 8
}

# Final error screen before exiting
function errorScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--msgbox "WARNING: Could not receive all save data updates from the cloud. To minimize potential data loss, automatic syncing will be stopped for this session. For more info, see the log file at:\n${LOG_FILE}" \
		16 56 8
}

#####
# APP
#####
# Main function
#
# @returns 0 if all cloud syncs are successful
function bootSync() {
	local exitCode=0

	# Check for dirty boot
	if [ -f "${DIRTY_BOOT}" ]; then
		dirtyBootScreen
		rm "${DIRTY_BOOT}"
	fi

	# Check for network connection
	networkCheckScreen
	exitCode=$?

	# Receive cloud sync
	if [ "${exitCode}" = 0 ]; then
		receiveCloudUpdatesScreen
		exitCode=$?
	fi

	# Try again if there were any errors
	if [ "${exitCode}" != 0 ]; then
		tryAgainScreen

		# Allow user to start over
		if [ $? = 0 ]; then
			bootSync
			# Get recursion process return code
			# so it doesn't get overwritten by the current value
			exitCode=$?

		# Warn user of error, stop automatic sync, and set dirty boot lockfile
		else
			errorScreen

			stopPathUnits

			touch "${DIRTY_BOOT}"
		fi
	fi

	return $exitCode
}

#####
# RUN
#####
clear

bootSync

exit $?
