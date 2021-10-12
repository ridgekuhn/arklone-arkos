#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t getFilterString)" = "function" ] || source "${ARKLONE[installDir]}/rclone/scripts/functions/getFilterString.sh"

# Send a directory to rclone remote
#
# @param $1 {string} Absolute path to local directory. No trailing slash.
#
# @param $2 {string} Path to remote dir. No opening slash.
#
# @param [$3] {string} Optional list of pipe-delimited rclone filter names
#
# @returns Exit code of rclone process
function sendDir() {
	[ $1 ] || return 64
	[ $2 ] || return 64

	local localDir="${1}"
	local remoteDir="${2}"
	local filters="${3}"

	local filterString="$(getFilterString "${filters}")"

	printf "\nSending ${localDir} to ${ARKLONE[remote]}:arklone/${remoteDir}\n"

	rclone copy "${localDir}/" "${ARKLONE[remote]}:arklone/${remoteDir}/" ${filterString} -u -v --config "${ARKLONE[rcloneConf]}"

	return $?
}

