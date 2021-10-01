#!/bin/bash
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
		if [ -z ${dir##*/$ignoreDir} ]; then
			echo "${dir} is in ignore list: ${2}. Skipping..."
			echo ""

			return
		fi
	done

	return 1
}
