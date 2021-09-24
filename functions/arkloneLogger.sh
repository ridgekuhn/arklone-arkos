#!/bin/bash
# Log output to file
#
# Deletes old log file if older than system uptime,
# or appends to log if valid for this session
#
# @param $1 {string} Path to log file
function arkloneLogger() {
	local logFile="${1}"
	local deleteOldLog="${2}"

	# Delete log if last modification is older than system uptime
	if
		[ "${deleteOldLog}" = "true" ] \
		&& [ -f "${logFile}" ] \
		&& [ $(($(date +%s) - $(date +%s -r "${logFile}"))) -gt $(awk -F . '{print $1}' "/proc/uptime") ]
	then
		rm -f "${logFile}"
	fi

	# Begin logging
	if touch "${logFile}"; then
		exec &> >(tee -a "${logFile}")
	else
		echo "ERROR: Could not open log file..."
		return 1
	fi
}
