#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Load config file to array
#
# Parses a config file in the format:
# 'someOption = "someSetting"'
# without single-quotes, one per line
#
# Populates passed array $2 like:
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
#
# @param $2 {var} Name-reference of array to append to
#
# @param [$3] {string} Optional pattern to match
function loadConfig() {
    local cfgFile="${1}"
    local -n arr=$2
    local pattern="${3}"

    # Error if no user config found
    if [ ! -f "${cfgFile}" ]; then
        echo "ERROR: ${cfgFile} not found!"
        exit 72
    fi

    # Parse user config file
    while read line; do
        if grep -F '=' <<<"${line}" >/dev/null 2>&1; then
            # Get the option name
            local option=$(sed -e 's/ *=.*$//' <<<"${line}")

            # Add the option/value to ${arr[@]}
            arr[$option]=$(sed -e 's/^.*= *"//' -e 's/" *$//' <<<"${line}")
        fi
    done < <(grep -E "${pattern}" "${cfgFile}")
}

