#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Edit an option setting in a config file
#
# Where config values are stored in a newline-delimited file as:
# 'someSetting = "someValue"''
#
# @param $1 {string} The name of the option
#
# @param $2 {string} The new value to save
#
# @param [$3] {boolean} Comment/disable setting
#
# @param ${@: -1} {string} Path to the config file to edit
function editConfig() {
    local option="${1}"
    local newVal="${2}"
    local comment="$([[ "${3}" = "true" ]] && echo "# ")"
    local cfg="${@: -1}"

    local newSettingString="${comment}${option} = \"${newVal}\""

    # If option exists in file
    if grep -E "^( *#)? *${option} *=" "${cfg}" >/dev/null 2>&1; then
        # @todo why don't non-capturing groups work? eg, (?: *#)
        sed -i -E "s|^( *#)? *${option} *=.*|${newSettingString}|" "${cfg}"

    # Create non-existent option
    else
        echo "${newSettingString}" >> "${cfg}"
    fi
}

