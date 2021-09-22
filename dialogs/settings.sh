#!/bin/bash
# arklone settings utility
# by ridgek
########
# CONFIG
########
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/loadConfig.sh"
source "${ARKLONE[installDir]}/functions/editConfig.sh"
source "${ARKLONE[installDir]}/functions/printMenu.sh"
source "${ARKLONE[installDir]}/dialogs/functions/alreadyRunning.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

#############
# CONTROLLERS
#############
# Manual backup ArkOS settings
function manualBackupArkOS() {
	local keep="${1}"

	. "${ARKLONE[installDir]}/rclone/scripts/sync-arkos-backup.sh"

	if [ $? = 0 ]; then
		# Delete ArkOS settings backup file
		if [ $keep != 0 ]; then
			sudo rm -v "${ARKLONE[backupDir]}/arkosbackup.tar.gz"
		fi

		return 0
	else
		return $?
	fi
}

#######
# VIEWS
#######
# Point-of-entry dialog
function homeScreen() {
	# Set automatic sync mode string
	local ableString=[ "${ARKLONE[autoSync]}" ] && echo "Disable" || echo "Enable"

	local selection=$(whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--menu "Choose an option:" \
			16 60 8 \
			"1" "Set cloud service (now: $([ "${ARKLONE[remote]}" ] && echo ${ARKLONE[remote]} || echo "NONE"))" \
			"2" "Manual sync savefiles/savestates" \
			"3" "${ableString} automatic saves sync" \
			"4" "Manual backup/sync ArkOS Settings" \
			"5" "Regenerate RetroArch path units" \
			"x" "Exit" \
		3>&1 1>&2 2>&3 \
	)

	case $selection in
		1) setCloudScreen ;;
		2) manualSyncSavesScreen ;;
		3) autoSyncSavesScreen ;;
		4) manualBackupArkOSScreen ;;
		5) regenRAunitsScreen ;;
	esac
}

# First run dialog
function firstRunScreen() {
	# Check if rclone is configured
	if [ -z "$(rclone listremotes 2>/dev/null)" ]; then
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--msgbox "It looks like you haven't configured any rclone remotes yet! Please see the documentation at:\nhttps://github.com/ridgekuhn/arklone\nand\nhttps://rclone.org/docs/" \
			16 56 8

		exit
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

		. "${ARKLONE[installDir]}/retroarch/set-recommended-settings.sh"
	fi

	# Generate RetroArch systemd path units
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--msgbox "We will now install several components for syncing RetroArch savefiles/savestates. This process may take several minutes, depending on your configuration." \
			16 56 8

	regenRAunitsScreen
}

# Cloud service selection dialog
function setCloudScreen() {
	# Get list of rclone remotes
	local remotes=($(rclone listremotes | cut -d ':' -f 1))

	local selection=$(whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--menu \
			"Choose a cloud service:" \
			16 60 8 \
			$(printMenu "${REMOTES[@]}") \
		3>&1 1>&2 2>&3 \
	)

	# Save user selection and reload config
	if [ "${selection}" ]; then
		editConfig "remote" "${remotes[$selection]}" "${ARKLONE[log]}"
		loadConfig "${ARKLONE[userCfg]}" ARKLONE
	fi

	homeScreen
}

# Manual sync savefiles/savestates dialog
function manualSyncSavesScreen() {
	local script="${ARKLONE[installDir]}/rclone/scripts/send-and-receive-saves.sh"
	local instances=($(getRootInstanceNames))
	local localdirs=$(for instance in ${instances[@]}; do filter="$(echo ${instance##*@} | awk -F '-' '/retroarch/ {$2!=""?str=$2:str=$1; str="("str")"; print str}')"; printf "${instance%@*@*}${filter} "; done)

	alreadyRunning "${script}"

	if [ $? != 0 ]; then
		homeScreen
	else
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
			"${script}" "${instance}"

			if [ $? = 0 ]; then
				whiptail \
					--title "${ARKLONE[whiptailTitle]}" \
					--msgbox \
						"${localdir} synced to ${ARKLONE[remote]}:${remotedir}. Log saved to ${ARKLONE[log]}." \
						16 56 8
			else
				whiptail \
					--title "${ARKLONE[whiptailTitle]}" \
					--msgbox \
						"Update failed. Please check the log file at ${ARKLONE[log]}." \
						16 56 8
			fi
		fi

		homeScreen
	fi
}

# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	. "${ARKLONE[installDir]}/systemd/scripts/enable-disable-path-units.sh"

	# Fix incompatible settings
	if [ $? = 65 ]; then
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--yesno \
				"You have the following incompatible settings enabled in your retroarch.cfg files. Would you like us to disable them?:\n
				savefiles_in_content_dir\n
				savestates_in_content_dir" \
			16 56 8

		if [ $? = 1 ]; then
			whiptail \
				--title "${ARKLONE[whiptailTitle]}" \
				--msgbox "No action has been taken. You may still use the manual sync feature for RetroArch savefiles/savestates, but you will not be able to automatically sync them until the incompatible settings in retroarch.cfg are resolved." \
			16 56 8
		else
			# Get array of all retroarch.cfg instances
			local retroarchs=(${ARKLONE[retroarchCfg]})

			# Change user settings
			for retroarchCfg in ${RETROARCHS[@]}; do
				. "${ARKLONE[installDir]}/retroarch/scripts/set-recommended-settings.sh" "${retroarchCfg}"
			done

			autoSyncSavesScreen

			return
		fi
	fi

	# Reset ${ARKLONE[autoSync]}
	$ARKLONE[autoSync]=$(systemctl list-unit-files arkloned* | grep "enabled" | cut -d " " -f 1)

	homeScreen
}

# Manual backup ArkOS settings screen
function manualBackupArkOSScreen() {
	local script="${ARKLONE[installDir]}/rclone/scripts/send-arkos-backup.sh"

	alreadyRunning "${script}"

	if [ $? != 0 ]; then
		homeScreen
	else
		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--yesno \
				"This will create a backup of your settings at ${ARKLONE[backupDir]}/arkosbackup.tar.gz. Do you want to keep this file after it is uploaded to ${ARKLONE[remote]}?" \
				16 56

		local keep=$?

		whiptail \
			--title "${ARKLONE[whiptailTitle]}" \
			--infobox \
				"Please wait while we back up your settings..." \
				16 56 8

		manualBackupArkOS "${keep}"

		if [ $? = 0 ]; then
			whiptail \
				--title "${ARKLONE[whiptailTitle]}" \
				--msgbox \
					"ArkOS backup synced to ${ARKLONE[remote]}:ArkOS. Log saved to ${ARKLONE[log]}." \
					16 56 8
		else
			whiptail \
				--title "${ARKLONE[whiptailTitle]}" \
				--msgbox \
					"Update failed. Please check the log file at ${ARKLONE[log]}." \
					16 56 8
		fi

		homeScreen
	fi
}

# Regenerate RetroArch savestates/savefiles units screen
function regenRAunitsScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh" true

	homeScreen
}

#####
# RUN
#####
# If ${ARKLONE[remote]} doesn't exist,
# assume this is the user's first run
if [ -z "${ARKLONE[remote]}" ]; then
	firstRunScreen
fi

homeScreen
