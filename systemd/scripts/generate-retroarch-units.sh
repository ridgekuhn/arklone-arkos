#!/bin/bash
# arklone retroarch systemd unit generator
# by ridgek
########
# CONFIG
########
source "/opt/arklone/config.sh"

#########
# HELPERS
#########
# Check if a unit for this path and ${savetype} (filter) already exists
#
# @param $1 {string} The local directory to watch
# @param $2 {string} The rclone filter in ${ARKLONE_DIR}/rclone/filters,
# 	named "retroarch-${savetype}" (no extension)
#
# @returns 1 if a unit already exists
function unitExists() {
	local localDir="${1}"
	local filter="${2}"
	local existingUnits=($(find "${ARKLONE_DIR}/systemd/units/"*".path"))

	for existingUnit in ${existingUnits[@]}; do
		local pathChanged=$(awk -F '=' '/PathChanged/ {print $2}' "${existingUnit}")
		local escInstanceName=$(awk -F "=" '/Unit/ {split($2, arr, "arkloned@"); print arr[2]}' "${existingUnit}")
		local existingFilter=$(systemd-escape -u -- "${escInstanceName}" | awk -F '@' '{split($3, arr, ".service"); print arr[1]}')

		if [ "${pathChanged}" = "${localDir}" ]; then
			if [ "${existingFilter}" = "${filter}" ] \
				|| [ ! -z ${existingFilter} ] \
				&& [ -z ${filter##$existingFilter*} ]
			then
				return 1
			fi
		fi
	done
}

# Make a new path unit
#
# If ! -z ${AUTOSYNC}, also enables and starts the new unit
#
# @param $1 {string} Absolute path to the new unit file. Must end in .auto.path
# @param $2 {string} The directory to watch for changes
# @param $3 {string} The remote directory to sync rclone to
# @param [$4] {string} The rclone filter in ${ARKLONE_DIR}/rclone/filters (no extension)
function makePathUnit() {
	local newUnit="${1}"
	local localDir="${2}"
	local remoteDir="${3}"
	local filter="${4}"

	local instanceName=$(systemd-escape "${localDir}@${remoteDir}@${filter}")

	# Skip if a unit already exists for this path
	unitExists "${localDir}" "${filter}"

	if [ $? != 0 ]; then
		echo "A path unit for ${localDir} using ${filter}.filter already exists. Skipping..."
		return
	fi

	# Generate new unit
	echo "Generating new path unit: ${newUnit}"
	sudo cat <<EOF > "${newUnit}"
[Path]
PathChanged=${localDir}
Unit=arkloned@${instanceName}.service

[Install]
WantedBy=multi-user.target
EOF

	# Enable unit if auto-syncing is enabled
	if [ ! -z ${AUTOSYNC} ]; then
		sudo systemctl enable "${newUnit}" \
			&& sudo systemctl start "${newUnit##*/}"
	fi
}

# Recurse directory and make path units for subdirectories
#
# @param $1 {string} Absolute path to the directory to recurse
# @param $2 {string} Remote directory root path
# @param $3 {string} The rclone filter in ${ARKLONE_DIR}/rclone/filters (no extension)
# @param [$4] {string} Absolute path to list of directory names to ignore
function makeSubdirPathUnits() {
	local subdirs=$(find "${1}" -mindepth 1 -maxdepth 1 -type d)
	local remoteDir="${2}"
	local filter="${3}"
	local ignoreList="${4}"

	local ignoreDirs=($(cat "${ignoreList}" 2>/dev/null))

	# Workaround for subdirectory names with spaces
	local OIFS="$IFS"
	IFS=$'\n'

	for subdir in ${subdirs[@]}; do
		local unit="${ARKLONE_DIR}/systemd/units/arkloned-${remoteDir//\//-}-$(basename "${subdir//\ /_}").sub.auto.path"

		# Skip non-RetroArch subdirs
		if [ ! -z "${ignoreDirs}" ]; then
			local skipDir=false

			for ignoreDir in ${ignoreDirs[@]}; do
				if [ -z ${subdir##*/$ignoreDir} ]; then
					skipDir=true
				fi
			done

			if [ "${skipDir}" = "true" ]; then
				echo "${subdir} is in ignore list: ${ignoreList}. Skipping..."
				continue
			fi
		fi

		makePathUnit "${unit}" "${subdir}" "${remoteDir}/${subdir##*/}" "${filter}"
	done

	# Reset workaround for directory names with spaces
	IFS="$OIFS"
}

#####
# RUN
#####
OLD_UNITS=($(find "${ARKLONE_DIR}/systemd/units/arkloned-retroarch"*".auto.path" 2>/dev/null))
IGNORE_DIRS="${ARKLONE_DIR}/systemd/scripts/retroarch-roms.ignore"

# Remove old units
if [ ! -z ${OLD_UNITS} ]; then
	echo "Cleaning up old path units..."

	for OLD_UNIT in ${OLD_UNITS[@]}; do
		linked=$(systemctl list-unit-files | awk -v OLD_UNIT="${OLD_UNIT##*/}" '$0~OLD_UNIT {print $1}')

		printf "\nRemoving old unit: ${OLD_UNIT##*/}...\n"

		if [ ! -z $linked ]; then
			sudo systemctl disable "${OLD_UNIT##*/}"
		fi

		sudo rm -v "${OLD_UNIT}"
	done
fi

# Make RetroArch content path units
for retroarch_dir in ${RETROARCHS[@]}; do
	# Get retroarch or retroarch32
	retroarch=${retroarch_dir##*/}
	savetypes=("savefile" "savestate")

	savefiles_in_content_dir=$(awk '/savefiles_in_content_dir/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")
	savestates_in_content_dir=$(awk '/savestates_in_content_dir/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")

	savefile_directory=$(awk -v homeDir="/home/${USER}" '/savefile_directory/ {gsub("\"","",$3); gsub("~",homeDir,$3); print $3}' "${retroarch_dir}/retroarch.cfg")
	savestate_directory=$(awk -v homeDir="/home/${USER}" '/savestate_directory/ {gsub("\"","",$3); gsub("~",homeDir,$3); print $3}' "${retroarch_dir}/retroarch.cfg")

	sort_savefiles_enable=$(awk '/sort_savefiles_enable/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")
	sort_savestates_enable=$(awk '/sort_savestates_enable/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")

	# @TODO `sort_${savetype}s_by_content_enable = "true"`
	#		works in ArkOS, but appears to have no effect on the default
	#		Windows, MacOS, and Debian binaries,
	#		so we are not supporting it at this time.
	#
	#		If this changes, we will have to rewrite all code which follows.
	#
	#		The expected behavior is:
	#
	#		`sort_${savetype}s_by_content_enable = "true"`
	#		`sort_${savetype}s_enable = "false"`
	#		Save directory: ${savetype_directory}/${system}
	#
	#		`sort_${savetype}s_by_content_enable = "true"`
	#		`sort_${savetype}s_enable = "true"`
	#		Save directory: ${savetype_directory}/${system}/${libRetroCore}
	sort_savefiles_by_content_enable=$(awk '/sort_savefiles_by_content_enable/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")
	sort_savestates_by_content_enable=$(awk '/sort_savestates_by_content_enable/ {gsub("\"","",$3); print $3}' "${retroarch_dir}/retroarch.cfg")

	if [ "$sort_savefiles_by_content_enable" = "true" ] \
		|| [ "$sort_savestates_by_content_enable" = "true" ]; then
		echo "sort_savefiles_by_content_enable and sort_savestates_by_content_enable are not supported by arklone. Please change these settings to "false" in ${retroarch_dir}/retroarch.cfg and try again."
		exit 73
	fi

	#####################################################################
	# Scenario 1:
	# savefiles and savestates are both stored in the content directories
	#####################################################################
	if [ "$savefiles_in_content_dir" = "true" ] \
		&& [ "$savestates_in_content_dir" = "true" ]
	then
		# Make RetroArch content root unit
		unit="${ARKLONE_DIR}/systemd/units/arkloned-${retroarch}-${RETROARCH_CONTENT_ROOT##*/}.auto.path"
		makePathUnit "${unit}" "${RETROARCH_CONTENT_ROOT}" "${retroarch}/${RETROARCH_CONTENT_ROOT##*/}" "retroarch"

		# Make RetroArch content subdirectory units
		makeSubdirPathUnits "${RETROARCH_CONTENT_ROOT}" "${retroarch}/${RETROARCH_CONTENT_ROOT##*/}" "retroarch" "${IGNORE_DIRS}"

		# Go to next ${retroarch_dir}
		continue
	fi

	#########################################################################
	# Scenario 2:
	# savefiles and savestates are in the same directory,
	# but outside the content directory
	#########################################################################
	if [ "$savefiles_in_content_dir" != "true" ] \
		&& [ "$savestates_in_content_dir" != "true" ] \
		&& [ "${savefile_directory}" = "${savestate_directory}" ]
	then
		# Make RetroArch save root unit
		unit="${ARKLONE_DIR}/systemd/units/arkloned-${retroarch}-${savefile_directory##*/}.auto.path"
		makePathUnit "${unit}" "${savefile_directory}" "${retroarch}/${savefile_directory##*/}" "retroarch"

		########################################
		# Scenario 2A:
		# savefiles and savestates are sorted
		# and saved into the same subdirectories
		########################################
		if [ "${sort_savefiles_enable}" = "true" ] \
			&& [ "${sort_savestates_enable}" = "true" ]
		then
			makeSubdirPathUnits "${savefile_directory}" "${retroarch}/${savefile_directory##*/}" "retroarch"

		#################################################
		# Scenario 2B
		# only one of savefiles and savestates are sorted
		#################################################
		elif [ "${sort_savefiles_enable}" = "true" ] \
			|| [ "${sort_savestates_enable}" = "true" ]
		then
			for savetype in ${savetypes[@]}; do
				sort_savetypes_enable="sort_${savetype}s_enable"

				if [ "${!sort_savetypes_enable}" = "true" ]; then
					makeSubdirPathUnits "${savefile_directory}" "${retroarch}/${savefile_directory##*/}" "retroarch-${savetype}"
				fi
			done
		fi

		# Go to next ${retroarch_dir}
		continue
	fi

	##########################################################
	# Scenario 3:
	# Savefiles and savestates are NOT in the same directories
	##########################################################
	for savetype in ${savetypes[@]}; do
		# Get settings from ${retroarch}/retroarch.cfg
		savetypes_in_content_dir="${savetype}s_in_content_dir"
		savetype_directory="${savetype}_directory"
		sort_savetypes_enable="sort_${savetype}s_enable"

		# Make RetroArch content directory units
		if [ "${!savetypes_in_content_dir}" = "true" ]; then
			# Make RetroArch content root unit
			unit="${ARKLONE_DIR}/systemd/units/arkloned-${retroarch}-${RETROARCH_CONTENT_ROOT##*/}-${savetype}s.auto.path"
			makePathUnit "${unit}" "${RETROARCH_CONTENT_ROOT}" "${retroarch}/${RETROARCH_CONTENT_ROOT##*/}" "retroarch-${savetype}"

			# Make RetroArch content subdirectory units
			makeSubdirPathUnits "${RETROARCH_CONTENT_ROOT}" "${retroarch}/${RETROARCH_CONTENT_ROOT##*/}" "retroarch-${savetype}" "${IGNORE_DIRS}"

		# Make ${savetype_directory} units
		else
			# Make ${savetype_directory} root path unit
			unit="${ARKLONE_DIR}/systemd/units/arkloned-${retroarch}-${savetype}s.auto.path"
			makePathUnit "${unit}" "${!savetype_directory}" "${retroarch}/${savetype}s" "retroarch-${savetype}"

			if [ "${!sort_savetypes_enable}" = "true" ]; then
				makeSubdirPathUnits "${!savetype_directory}" "${retroarch}/${savetype}s" "retroarch-${savetype}"
			fi
		fi
	done
done
