#!/bin/bash
# Load config file to array
#
# Parses a config file in the format:
# 'someOption = "someSetting"'
# without single-quotes, one per line
#
# Results in new values in passed array:
# myArray[someOption]="someSetting"
#
# @usage
#		declare -A MYARRAY
#		MYARRAY=(
#			[foo]="bar"
#		)
#
#		loadConfig "/path/to/cfg" MYARRAY
#
# @param $1 {string} Path to config file
# @param $2 {var} Array to append to
# @param [$3] {string} Optional pattern to match
function loadConfig() {
	local cfgFile="${1}"
	local -n arr=$2
	local pattern="${3}"

	# Error if no user config found
	if [ ! -f "${cfgFile}" ]; then
		echo "ERROR: ${cfgFile} not found!"
		exit 1
	fi

	# Parse user config file
	while read line; do
		if grep -F '=' <<<"${line}" &>/dev/null; then
			# Get the option name
			local option=$(sed -e 's/ *=.*$//' <<<"${line}")

			# Add the option/value to ${arr[@]}
			arr[$option]=$(sed -e 's/^.*= *"//' -e 's/" *$//' <<<"${line}")
		fi
	done < <(grep -E "${3}" "${cfgFile}")
}
