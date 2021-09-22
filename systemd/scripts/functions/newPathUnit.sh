#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
#########
# HELPERS
#########
# Check if a path unit using a local directory and rclone filter already exists
#
#	If filter is not a duplicate, function returns with code 1
#	and outputs a pipe | delimited string to STDERR,
#	containing all the existing filters, plus the new one passed in $2
#
#	@usage
#		newFilterList=$((unitExists "/path/to/localDir" "some-filter") 2>&1)
#
#		if [ $? != 0 ] && [ "${newFilterList}" ]; then
#			echo "${newFilterList}"
#			# some-filter|some-other-filter|yet-another-filter
#		fi
#
# @param $1 {string} Absolute path to local directory
# @param $2 {string} rclone filter name
#		ie, the name of the file in ${ARKLONE[installDir]}/rclone/filters,
#		without the .filter extension
#
# @returns 1 if an existing unit is NOT found
#		and outputs pipe | delimited list of all filters to STDERR
function unitExists() {
	local localDir="${1}"
	local filter="${2}"
	local existingUnits=($(find "${ARKLONE[installDir]}/systemd/units/"*".path"))

	# Loop through existing units
	for existingUnit in ${existingUnits[@]}; do
		# Get the existing unit's watched directory path
		local existingDir=$(grep "PathChanged" "${existingUnit}" | cut -d '=' -f 2)

		# If ${localDir} is already being watched,
		# check if ${filter} is also being used
		if [ "${existingDir}" = "${localDir}" ]; then
			# Get the escaped instance name from the Unit= line
			# eg, "-home-ark.config-retroarch-saves\x40retroarch-savefiles\x40retroarch\x2dsavefile\x7cretroarch\x2dsavestate"
			local escInstanceName=$(grep "Unit" "${existingUnit}" | sed -e 's/^arkloned@//' -e 's/.service$//')

			# Get the existing unit's unescaped, pipe | delimited list of filters,
			# and store it in an array
			# eg, "retroarch-savefile|retroarch-savestate" in above example
			local existingFilters=($(systemd-escape -u -- "${escInstanceName}" | cut -d '@' -f 3- | tr '|' '\n'))

			# Create a sorted array from ${filter} and ${existingFilters}
			local allFilters=($(tr ' ' '\n' <<<"${filter} ${existingFilters[@]}" | sort))

			# If doubles are found, the unit DOES exist. Return with code 0
			if [ "$(tr ' ' '\n' <<<"${allFilters[@]}" | uniq -d)" ]; then
				return 0

			# If no doubles are found, unit does not exist, return error code 1
			else
				# Convert filter list to a pipe | delimited string
				local filterString=$(tr ' ' '\n' <<<"${allFilters[@]}" | uniq | tr '\n' '|')

				# Echo ${filterString} to stderr and remove any trailing pipe | characters
				echo "${filterString%%|}" >&2

				return 1
			fi
		fi
	done

	# If we made it this far, no units exist, so return error code 1
	return 1
}

######
# MAIN
######
# Make new systemd path unit
#
# Creates a new systemd path unit file in ${ARKLONE[installDir]}/systemd/units/
# using the the arkloned@.service unit template.
#
# @see systemd/units/arkloned@.service
#
# @usage
#		newPathUnit "retroarch32-savestate" "/path/to/savestates/nes" "retroarch32/nes" "retroarch-savefile|retroarch-savestate"
#
#		Creates a new path unit at:
#		"/opt/arklone/systemd/units/arkloned-retroarch32-savestate.path",
#		with service instance template name (unescaped):
#		"/path/to/savestates/nes@retroarch/nes@retroarch-savefile|retroarch-savestate"
#
#		New unit syncs local directory:
#		"/path/to/savestates/nes"
#		with remote directory
#		"retroarch/nes",
#		using the rclone filters at
#		"/opt/arklone/rclone/filters/retroarch-savefile.filter"
#		"/opt/arklone/rclone/filters/retroarch-savestate.filter"
#
# @param $1 {string} Name of the new path unit.
#		Should usually be the name of the remote directory.
#		Do not pass names ending with .auto or .sub.auto
#		they are reserved for use by arklone.
#	@param $2 {string} Local path to watch for changes
#	@param $3 {string} Remote path to sync with
# @param [$4] {string} Pipe | delimited list of rclone filter names
#		ie, the name of the file in ${ARKLONE[installDir]}/rclone/filters,
#		without the .filter extension
function newPathUnit() {
	local unitName="${1}"
	local localDir="${2}"
	local remoteDir="${3}"
	local filter="${4}"

	# Check if a path unit using this filter already exists,
	# and capture stderr output from unitExists()
	# in case it finds a unit using the path but not the filter
	local filterString=$((unitExists "${localDir}" "${filter}") 2>&1)

	# If a unit using ${localDir} and ${filter} was found
	if [ $? = 0 ]; then
		echo "A path unit for ${localDir} using ${filter}.filter already exists. Skipping."

		return 1

	# If a path unit was found, but not using ${filter},
	# set ${filter} to the filter string captured from unitExists()
	elif [ "${filterString}" ]; then
		echo "A path unit was found, but not using ${filter}.filter"
		echo "Unit will be re-generated with filters:"
	 	echo "$(tr '|' ' ' <<<"${filterString}")"

		filter="${filterString}"
	fi

	# Make an instance name, escaped for systemd
	#
	# Unescaped instance name:
	# "/home/ark/.config/retroarch/saves@retroarch-savefiles@retroarch-savefile"
	# Escaped instance name:
	# "-home-ark.config-retroarch-saves\x40retroarch-savefiles\x40retroarch\x2dsavefile"
	local instanceName=$(systemd-escape "${localDir}@${remoteDir}@${filter}")

	# Generate the new unit
	echo "Creating new path unit: ${ARKLONE[installDir]}/systemd/units/arkloned-${unitName}.path"

	cat <<EOF > "${ARKLONE[installDir]}/systemd/units/arkloned-${unitName}.path"
[Path]
PathChanged=${localDir}
Unit=arkloned@${instanceName}.service

[Install]
WantedBy=multi-user.target
EOF

	# For readability
	echo ''
}

