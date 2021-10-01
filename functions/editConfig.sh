#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Edit an option setting in a config file
#
# Where config values are stored like:
# 'someSetting = "someValue"''
# without single-quotes, one per line
#
# @param $1 {string} The name of the option
#
# @param $2 {string} The new value to save
#
# @param $3 {string} Path of the file to edit
function editConfig() {
	local option="${1}"
	local newVal="${2}"
	local cfg="${3}"

	sed -i 's|^'${option}'.*=.*|'${option}' = "'${newVal}'"|' "${3}"
}

