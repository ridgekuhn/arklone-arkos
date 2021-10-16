#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t unitExists)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/unitExists.sh"

# Make new systemd path unit
#
# Creates a new systemd path unit file in ${ARKLONE[installDir]}/systemd/units/
# using the the arkloned@.service unit template.
# @see systemd/units/arkloned@.service
#
# Checks all existing path units for
# the same local sync directory passed to $2
# If a unit is found, attempts to
# apply the new rclone filter to the existing unit
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
	local filterString
	filterString="$((unitExists "${localDir}" "${filter}") 2>&1)"

	# If a unit using ${localDir} and ${filter} was found
	if [ $? = 0 ]; then
		echo "A path unit for ${localDir} using ${filter}.filter already exists. Skipping."

		return 1

	# If a path unit was found, but not using ${filter},
	# set ${filter} to the filter string captured from unitExists()
	elif [ "${filterString}" ]; then
		echo "A path unit was found, but not using ${filter}.filter"
		echo "Unit will be re-generated with filters: $(tr '|' ' ' <<<"${filterString}")"

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
	echo "Creating instance: ${localDir}@${remoteDir}@${filter} at ${ARKLONE[unitsDir]}/arkloned-${unitName}.path"

	cat <<EOF > "${ARKLONE[unitsDir]}/arkloned-${unitName}.path"
[Path]
PathChanged=${localDir}
Unit=arkloned@${instanceName}.service

[Install]
WantedBy=multi-user.target
EOF

	# For stdout readability
	echo ''
}

