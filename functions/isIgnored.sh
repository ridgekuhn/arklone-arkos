#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Check if passed file or directory is in ignore list
#
# Ignore list should be a text file of file/directory names, one per line
# Wildcard * is allowed, but only the basename of the file is checked
# (leading path/slashes are dropped)
#
# @param $1 {string} Path of file to check
#
# @param $2 {string} Path to ignore list
#
# @returns 1 if $1 is NOT in ignore list
function isIgnored() {
    local checkedFile="${1}"
    local ignoreList=($(cat "${2}" 2>/dev/null))

    for ignoredFile in ${ignoreList[@]}; do
        if [ -z ${checkedFile##*/$ignoredFile} ]; then
            echo "${checkedFile} is in ignore list: ${2}. Skipping..."
            echo ""

            return
        fi
    done

    return 1
}

