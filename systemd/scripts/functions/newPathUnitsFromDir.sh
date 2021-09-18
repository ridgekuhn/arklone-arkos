#!/bin/bash
# @todo only source if func doesn't exist
source "/opt/arklone/systemd/scripts/functions/newPathUnit.sh"

#########
# HELPERS
#########
# Check if passed subdirectory is in ignore list
#
# Ignore list should be a text file of subdirectory names, one per line
# Wildcard * is allowed, but only the basename of the subdirectory is checked
# (leading path/slashes are dropped)
#
# @param $1 {string} Path to subdir to check
# @param $2 {string} Path to ignore list
#
# @returns 1 if $1 is NOT in ignore list
function isIgnored() {
	local dir="${1}"
	local ignoreList=($(cat "${2}" 2>/dev/null))

	for ignoreDir in ${ignoreList[@]}; do
		if [ -z ${subdir##*/$ignoreDir} ]; then
			echo "${subdir} is in ignore list: ${ignoreList}. Skipping..."
			return
		fi
	done

	return 1
}

######
# MAIN
######
# Make path unit for directory, and optionally for subdirectories
#
# @param $1 {string} Absolute path to the local parent directory
# @param $2 {string} Remote parent directory path.
#		No opening or trailing slashes.
# @param $3 {number} Depth of subdirectories to recurse
# @param [$4] {boolean} Create a path unit for the parent directory.
#		Defaults to true
# @param [$5] {string} Optional pipe | delimited list of rclone filter names in
#		${ARKLONE[installDir]}/rclone/filters
#		Pass file name only, no extension or leading directory path.
#		Filter will be shared by all subdirectory path units.
# @param [$6] {string} Optional absolute path
#		to a list of directory names to ignore
function newPathUnitsFromDir() {
	local localParentDir="${1}"
	local remoteParentDir="${2}"

	# Get subdirectories of depth $3
	local subdirs=$(find "${localParentDir}" -mindepth $3 -maxdepth $3 -type d)
	local createParentUnit=$([ -z $4 ] && echo true || echo "${4}")
	local filter="${5}"
	local ignoreList="${6}"

	local globalIgnoreList="${ARKLONE[installDir]}/systemd/scripts/ignores/global.ignore"

	# Save default $IFS
	local oIFS="${IFS}"

	#####
	# RUN
	#####
	# @todo Make root unit
	if [ "${createParentUnit}" = "true" ]; then
		# Convert forward slashes / in ${remoteParentDir} to hyphens -
		# eg,
		# remoteParentDir="retroarch32/savestates"
		# localParentDir="/path/to/savestates"
		# filter="retroarch-savestate"
		# newPathUnit "retroarch32-savestates.auto" "/path/to/savestates" "retroarch32/savestates" "retroarch-savestate"
		newPathUnit "${remoteParentDir//\//-}.auto" "${localParentDir}" "${remoteParentDir}" "${filter}"
	fi

	for subdir in ${subdirs[@]|}; do
		# Escape tab and space
		IFS=$'\n'

		# Build unit name
		#
		# Convert forward slashes / in ${remoteParentDir} to hyphens -
		#	Convert spaces in poorly-named ${subdir} to underscores _
		# Use basename to strip leading path from ${subdir}
		# eg,
		# remoteParentDir="retroarch32/savestates"
		# subDir="/path/to/poorly named dir"
		#	unitName="retroarch32-savestates-poorly_named_dir.sub.auto"
		local unitName="${remoteParentDir//\//-}-$(basename "${subdir//\ /_}").sub.auto"

		# Reset IFS
		IFS="${oIFS}"

		# Check ignore lists and continue to next subdir if in ignore list
		isIgnored "${subdir}" "${globalIgnoreList}" || isIgnored "${subdir}" "${ignoreList}"

		if [ $? = 0 ]; then
			continue
		fi

		# Make a new path unit
		# eg,
		# unitName="retroarch32"
		# subdir="/path/to/savestates/nes"
		# remoteParentDir="retroarch32"
		# filter="retroarch-savestate"
		#
		# newPathUnit "retroarch32" "/path/to/savestates/nes" "retroarch32/nes" "retroarch-savestate"
		newPathUnit "${unitName}" "${subdir}" "${remoteParentDir}/${subdir##*/}" "${filter}"
	done
}
