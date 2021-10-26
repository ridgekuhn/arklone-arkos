#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Sync one path unit
#
#	@usage
#		"${ARKLONE[installDir]}/src/rclone/scripts/sync-one-unit.sh" "send" "/path/to/localDir@remoteDir@filter1|filter2|etc"
#
# @param $1 {string} "send" or "receive"
#
# @param $2 {string} Path unit instance name in format:
#		${LOCALDIR}@${REMOTEDIR}@${FILTERS}
#		ie,
#		${LOCALDIR} Absolute path to local dir. No trailing slash.
#		${REMOTEDIR} Path to remote dir. No opening or trailing slash.
#		${FILTERS} rclone filter name
#
# @returns rclone exit code

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t arkloneLogger)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/arkloneLogger.sh"
[[ "$(type -t sendDir)" = "function" ]] || source "${ARKLONE[installDir]}/src/rclone/scripts/functions/sendDir.sh"
[[ "$(type -t receiveDir)" = "function" ]] || source "${ARKLONE[installDir]}/src/rclone/scripts/functions/receiveDir.sh"

# Exit if argument is invalid
[[ "${1}" = "send" ]] || [[ "${1}" = "receive" ]] || exit 64

# Set the sync function
# eg, sendDir or receiveDir
SYNC_FUNC="${1}Dir"

IFS="@" read -r LOCALDIR REMOTEDIR FILTERS <<< "${2}"

# Exit if instance name is malformed
[[ ! -z "${LOCALDIR}" ]] || exit 64
[[ ! -z "${REMOTEDIR}" ]] || exit 64

# Begin logging
arkloneLogger "${ARKLONE[log]}"

printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Run the sync function
"${SYNC_FUNC}" "${LOCALDIR}" "${REMOTEDIR}" "${FILTERS}"

exit $?

