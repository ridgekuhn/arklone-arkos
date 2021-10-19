#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Log output to file
#
# Deletes old log file if older than system uptime,
# or appends to log if valid for this session
#
# @param $1 {string} Path to log file
#
# @param [$2] {boolean} Optionally delete old log from previous boot if true
#
# @returns 1 if log file not found
function arkloneLogger() {
    local logFile="${1}"
    local deleteOldLog="${2}"

    # Delete log if last modification is older than system uptime
    if
        [ "${deleteOldLog}" = "true" ] \
        && [ -f "${logFile}" ] \
        && [ $(($(date +%s) - $(date +%s -r "${logFile}"))) -gt $(cut -d '.' -f 1 "/proc/uptime") ]
    then
        rm -f "${logFile}"
    fi

    # Begin logging
    if touch "${logFile}"; then
        # Start tee in background copy redirect stdout/stderr to it
        exec &> >(tee -a "${logFile}")

    else
        echo "ERROR: Could not open log file..."

        return 1
    fi
}

