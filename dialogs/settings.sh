#!/bin/bash
# arklone settings utility
# by ridgek
########
# CONFIG
########
source "./config.sh"

#########
# HELPERS
#########
source "${ARKLONE_DIR}/systemd/scripts/helpers/getRootInstanceNames.sh"

# Print items formatted for whiptail menu
#
# @param $1 {string} space-delimited array of menu options
#
# @returns {string} space-delimited array of menu indexes and options

function printMenu() {
	local items=($1)

	for (( i = 0; i < ${#items[@]}; i++ )); do
		printf "$i ${items[i]} "
	done
}

# Get log file path
#
# Checks script for ${LOG_FILE} variable
#
# @param $1 {string} Path of script to look for ${LOG_FILE} declaration in
#
# @returns Path of $1's ${LOG_FILE}
function getLogPath() {
	local script=$1
	echo $(awk '/^LOG_FILE/ { split($1, a, "="); gsub("\"", "", a[2]); print a[2]}' "${script}")
}

# Check if script is already running
#
# @param $1 {string} Path to script
#
# @param [$2] {string} Optional path to log file
#
# @returns 1 if $1 is an active process
function alreadyRunning() {
	local script="${1}"

	if [ ! -z "${2}" ]; then
		local log_file="${2}"
	else
		local log_file=$(getLogPath "${script}")
	fi

	local running=$(pgrep "${script##*/}")

	if [ ! -z "${running}" ]; then
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--yesno \
				"${script##*/} is already running. Would you like to see the log file?" \
				16 60

		if [ $? = 0 ]; then
			whiptail \
				--title "${log_file}" \
				--scrolltext \
				--textbox \
					"${log_file}" \
					16 60
		fi

		return 1
	fi
}

#############
# CONTROLLERS
#############
# Cloud service selection
#
# Saves selection to ${ARKLONE_DIR}/${REMOTE_CONF}
function setCloud() {
	local selection="${1}"

	local remotes=(${REMOTES})

	# Save selection to conf file
	echo ${remotes[$selection]} > $REMOTE_CONF

	# Reset string for current remote (for printing in homeScreen)
	REMOTE_CURRENT=$(awk '{print $1}' "${REMOTE_CONF}")
}

# Enable/Disable auto savefile/savestate path units
function autoSyncSaves() {
	# @TODO ArkOS exFAT bug
	#		A bug in ArkOS prevents systemd path units from being able to watch
	#		a subdirectory of an exFAT partition.
	#
	#		If EASYROMS is exFAT and user has either
	#		savefiles_in_content_dir or savestates_in_content_dir
	#		enabled in either retroarch or retroarch32's retroarch.cfg,
	#		then we will return with error 73.

	#		@see https://github.com/christianhaitian/arkos/issues/289
	local exfat=$(lsblk -f | awk -F " " '/EASYROMS/ {print $2}')

	if [ "${exfat}" = "exfat" ]; then
		for retroarch_dir in ${RETROARCHS[@]}; do
			local savetypes=("savefile" "savestate")

			for savetype in ${savetypes[@]}; do
				local savetypes_in_content_dir=$(awk -v savetypes_in_content_dir="${savetype}s_in_content_dir" '$0 ~ savetypes_in_content_dir {gsub("\"","",$3); print$3}' "${retroarch_dir}/retroarch.cfg")

				if [ "${savetypes_in_content_dir}" = "true" ]; then
					return 73
				fi
			done
		done
	fi

	# Generate and enable path units
	if [ -z "${AUTOSYNC}" ]; then
		# Generate new RetroArch path units
		"${ARKLONE_DIR}/systemd/scripts/generate-retroarch-units.sh"

		# Get all path units
		local units=($(find "${ARKLONE_DIR}/systemd/units/"*".path"))

		# If path units ending in *.sub.auto.path are found,
		# we should not enable the ${RETROARCH_CONTENT_ROOT} unit,
		# or the units for paths specified for
		# "savefile_directory" and "savestate_directory" in retroarch.cfg
		local noRootUnits=$(find "${ARKLONE_DIR}/systemd/units/"*".sub.auto.path")

		# Link path unit service template
		sudo systemctl link "${ARKLONE_DIR}/systemd/units/arkloned@.service"

		# Enable/start path units
		for unit in ${units[@]}; do
			# Skip root path units
			if
				[ $noRootUnits ] \
				&& [ "${unit:(-10)}" = ".auto.path" ] \
				&& [ "${unit:(-14)}" != ".sub.auto.path" ];
			then
				continue
			fi

			sudo systemctl enable "${unit}" \
				&& sudo systemctl start "${unit##*/}"
		done

		# Enable boot sync service
		sudo systemctl enable "${ARKLONE_DIR}/systemd/units/arkloned-saves-sync-boot.service"

	# Disable units
	else
		# Disable path units
		for unit in ${AUTOSYNC[@]}; do
			sudo systemctl disable "${unit}"
		done

		# Disable path unit service template
		sudo systemctl disable "arkloned@.service"

		# Disable boot sync service
		sudo systemctl disable arkloned-boot-sync.service
	fi

	# Reset able string
	AUTOSYNC=($(systemctl list-unit-files | awk '/arkloned/ && /enabled/ {print $1}'))
}

# Manual backup ArkOS settings
function manualBackupArkOS() {
	local keep="${1}"

	"${ARKLONE_DIR}/rclone/scripts/sync-arkos-backup.sh"

	if [ $? = 0 ]; then
		# Delete ArkOS settings backup file
		if [ $keep != 0 ]; then
			sudo rm -v "${BACKUP_DIR}/arkosbackup.tar.gz"
		fi

		return 0
	else
		return $?
	fi
}

# Disable RetroArch sort_savefiles_by_content_enable and sort_savefiles_by_content_enable
function disableRASortSavesByContent() {
	for retroarch_dir in ${RETROARCHS[@]}; do
		# Backup retroarch.cfg
		sudo cp ${retroarch_dir}/retroarch.cfg ${retroarch_dir}/retroarch.cfg.arklone.bak

		local savetypes=("savefile" "savestate")

		for savetype in ${savetypes[@]}; do
			echo "Disabling sort_${savetype}s_by_content_enable in ${retroarch_dir}/retroarch.cfg..."

			local oldSetting=$(grep "sort_${savetype}s_by_content_enable" "${retroarch_dir}/retroarch.cfg")
			local newSetting="sort_${savetype}s_by_content_enable = \"false\""

			sudo sed -i "s|${oldSetting}|${newSetting}|" "${retroarch_dir}/retroarch.cfg"
		done
	done
}

#	Set retroarch and retroarch32 retroarch.cfg files to the following settings:
#
# savefile_directory = "~/.config/retroarch/saves"
# savefiles_in_content_dir = "false"
# sort_savefiles_enable = "false"
# sort_savefiles_by_content_enable = "false"
#
# savestate_directory = "~/.config/retroarch/states"
# savestates_in_content_dir = "false"
# sort_savestates_enable = "false"
# sort_savestates_by_content_enable = "false"
function setRecommendedRASettings() {
	for retroarch_dir in ${RETROARCHS[@]}; do
		# Backup retroarch.cfg
		sudo cp ${retroarch_dir}/retroarch.cfg ${retroarch_dir}/retroarch.cfg.arklone.bak

		# Set savetype directories
		echo "Setting savefile_directory to ${retroarch_dir}/saves"

		if [ ! -d "${retroarch_dir}/saves" ]; then
			sudo mkdir "${retroarch_dir}/saves"
			sudo chmod a+rw "${retroarch_dir}/saves"
		fi

		local oldSavefileDir=$(grep "savefile_directory" "${retroarch_dir}/retroarch.cfg")
		local newSavefileDir="savefile_directory = \"${retroarch_dir}/saves\""

		sudo sed -i "s|${oldSavefileDir}|${newSavefileDir}|" "${retroarch_dir}/retroarch.cfg"

		echo "Setting savestate_directory to ${retroarch_dir}/states"

		if [ ! -d "${retroarch_dir}/states" ]; then
			sudo mkdir "${retroarch_dir}/states"
			sudo chmod a+rw "${retroarch_dir}/states"
		fi

		local oldSavestateDir=$(grep "savestate_directory" "${retroarch_dir}/retroarch.cfg")
		local newSavestateDir="savestate_directory = \"${retroarch_dir}/states\""

		sudo sed -i "s|${oldSavestateDir}|${newSavestateDir}|" "${retroarch_dir}/retroarch.cfg"

		# Set rest of settings
		local savetypes=("savefile" "savestate")

		for savetype in ${savetypes[@]}; do
			local settings=("${savetype}s_in_content_dir" "sort_${savetype}s_enable" "sort_${savetype}s_by_content_enable")

			for setting in ${settings[@]}; do
				echo "Setting ${setting} to \"false\""
				local oldSetting=$(grep "${setting}" "${retroarch_dir}/retroarch.cfg")
				local newSetting="${setting} = \"false\""

				sudo sed -i "s|${oldSetting}|${newSetting}|" "${retroarch_dir}/retroarch.cfg"
			done
		done
	done
}

#######
# VIEWS
#######
# Point-of-entry dialog
function homeScreen() {
	# Set automatic sync mode string
	if [ -z "${AUTOSYNC}" ]; then
		local able="Enable"
	else
		local able="Disable"
	fi

	local selection=$(whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--menu "Choose an option:" \
			16 60 8 \
			"1" "Set cloud service (now: $([ ! -z "${REMOTE_CURRENT}" ] && echo ${REMOTE_CURRENT} || echo "NONE"))" \
			"2" "Manual sync savefiles/savestates" \
			"3" "${able} automatic saves sync" \
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
			--title "${WHIPTAIL_TITLE}" \
			--msgbox "It looks like you haven't configured any rclone remotes yet! Please see the documentation at:\nhttps://github.com/ridgekuhn/arklone\nand\nhttps://rclone.org/docs/" \
			16 56 8

		exit
	fi

	# Set recommended RetroArch settings
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--yesno "Welcome to arklone!\nWould you like to automatically configure RetroArch to the recommended settings?" \
			16 56 8

	if [ $? = 0 ]; then
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--infobox \
				"Please wait while we configure your settings..." \
				16 56 8

		setRecommendedRASettings
	fi

	# Generate RetroArch systemd path units
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--msgbox "We will now install several components for syncing RetroArch savefiles/savestates. This process may take several minutes, depending on your configuration." \
			16 56 8

	regenRAunitsScreen
}

# Cloud service selection dialog
function setCloudScreen() {
	local selection=$(whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--menu \
			"Choose a cloud service:" \
			16 60 8 \
			$(printMenu "${REMOTES}") \
		3>&1 1>&2 2>&3 \
	)

	if [ ! -z "${selection}" ]; then
		setCloud "${selection}"
	fi

	homeScreen
}

# Manual sync savefiles/savestates dialog
function manualSyncSavesScreen() {
	local script="${ARKLONE_DIR}/rclone/scripts/sync-saves.sh"
	local log_file=$(getLogPath "${script}")
	local instances=($(getRootInstanceNames))
	local localdirs=$(for instance in ${instances[@]}; do filter="$(echo ${instance##*@} | awk -F '-' '/retroarch/ {$2!=""?str=$2:str=$1; str="("str")"; print str}')"; printf "${instance%@*@*}${filter} "; done)

	alreadyRunning "${script}"

	if [ $? != 0 ]; then
		homeScreen
	else
		local selection=$(whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--menu \
				"Choose a directory to sync with (${REMOTE_CURRENT}):" \
				16 60 8 \
				$(printMenu "${localdirs}") \
			3>&1 1>&2 2>&3 \
		)

		if [ ! -z "${selection}" ]; then
			local instance=${instances[$selection]}
			IFS="@" read -r localdir remotedir filter <<< "${instance}"

			# Sync the local and remote directories
			"${ARKLONE_DIR}/rclone/scripts/${script}" "${instance}"

			if [ $? = 0 ]; then
				whiptail \
					--title "${WHIPTAIL_TITLE}" \
					--msgbox \
						"${localdir} synced to ${REMOTE_CURRENT}:${remotedir}. Log saved to ${log_file}." \
						16 56 8
			else
				whiptail \
					--title "${WHIPTAIL_TITLE}" \
					--msgbox \
						"Update failed. Please check the log file at ${log_file}." \
						16 56 8
			fi
		fi

		homeScreen
	fi
}

# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	autoSyncSaves

	# Fix incompatible settings
	if [ $? = 73 ]; then
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--yesno \
				"You have the following incompatible settings enabled in your retroarch.cfg files. Would you like us to disable them?:\n
				savefiles_in_content_dir\n
				savestates_in_content_dir" \
			16 56 8

		if [ $? = 1 ]; then
			whiptail \
				--title "${WHIPTAIL_TITLE}" \
				--msgbox "No action has been taken. You may still use the manual sync feature for RetroArch savefiles/savestates, but you will not be able to automatically sync them until the incompatible settings in retroarch.cfg are resolved." \
			16 56 8
		else
			setRecommendedRASettings

			autoSyncSavesScreen

			return
		fi
	fi
	homeScreen
}

# Manual backup ArkOS settings screen
function manualBackupArkOSScreen() {
	local script="${ARKLONE_DIR}/rclone/scripts/sync-arkos-backup.sh"
	local log_file=$(getLogPath "${script}")

	alreadyRunning "${script}"

	if [ $? != 0 ]; then
		homeScreen
	else
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--yesno \
				"This will create a backup of your settings at ${BACKUP_DIR}/arkosbackup.tar.gz. Do you want to keep this file after it is uploaded to ${REMOTE_CURRENT}?" \
				16 56

		local keep=$?

		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--infobox \
				"Please wait while we back up your settings..." \
				16 56 8

		manualBackupArkOS "${keep}"

		if [ $? = 0 ]; then
			whiptail \
				--title "${WHIPTAIL_TITLE}" \
				--msgbox \
					"ArkOS backup synced to ${REMOTE_CURRENT}:ArkOS. Log saved to ${log_file}." \
					16 56 8
		else
			whiptail \
				--title "${WHIPTAIL_TITLE}" \
				--msgbox \
					"Update failed. Please check the log file at ${log_file}." \
					16 56 8
		fi

		homeScreen
	fi
}

# Regenerate RetroArch savestates/savefiles units screen
function regenRAunitsScreen() {
	whiptail \
		--title "${WHIPTAIL_TITLE}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	"${ARKLONE_DIR}/systemd/scripts/generate-retroarch-units.sh"

	# Fix incompatible settings
	if [ $? = 73 ]; then
		whiptail \
			--title "${WHIPTAIL_TITLE}" \
			--yesno \
				"You have the following incompatible settings enabled in your retroarch.cfg files. Would you like us to disable them?:\n
				sort_savefiles_by_content_enable\n
				sort_savestates_by_content_enable" \
			16 56 8

		if [ $? = 1 ]; then
			whiptail \
				--title "${WHIPTAIL_TITLE}" \
				--msgbox "No action has been taken. You will not be able to sync RetroArch savefiles/savestates until the incompatible settings in your retroarch.cfg files are disabled." \
			16 56 8
		else
			disableRASortSavesByContent

			regenRAunitsScreen

			return
		fi
	fi

	homeScreen
}

#####
# RUN
#####
# If ~/.config/arklone/remote.conf doesn't exist,
# assume this is the user's first run
if [ ! -f "${REMOTE_CONF}" ]; then
	firstRunScreen
fi

homeScreen
