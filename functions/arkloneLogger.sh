#!/bin/bash
# Log output to file
#
# Deletes old log file if older than system uptime,
# or appends to log if valid for this session
#
# @param $1 {string} Path to log file
function arkloneLogger() {
	local log_file="${1}"

	# Delete log if last modification is older than system uptime
	if [ -f "${log_file}" ] \
		&& [ $(($(date +%s) - $(date +%s -r "${log_file}"))) -gt $(awk -F . '{print $1}' "/proc/uptime") ]
	then
		rm -f "${log_file}"
	fi

	# Begin logging
	if touch "${log_file}"; then
		exec &> >(tee -a "${log_file}")
	else
		echo "ERROR: Could not open log file..."
		return 1
	fi
}
