#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Copy a directory's save data to the cloud, then receive new updates back
#
#	@usage
#		${ARKLONE[installDir]}/rclone/scripts/send-and-receive-saves.sh "/roms@retroarch/roms"
#
# @param $1 {string} directory paths in format: "${LOCALDIR}@${REMOTEDIR}@${FILTERS}
#		${LOCALDIR} should be absolute path, no trailing slash
#		${REMOTEDIR} no opening or trailing slashes
#		${FILTERS} name from file in ${ARKLONE[installDir]}/rclone/filters,
#			no leading directory path or .filter extension
#
# @returns 1 if no network connection, or rclone exit code

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t arkloneLogger)" = "function" ] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

IFS="@" read -r LOCALDIR REMOTEDIR FILTERS <<< "${1}"

FILTERSTRING="--filter-from ${ARKLONE[filterDir]}/global.filter"

# Append unit-specific filters if specified
if [ ! -z "${FILTERS}" ]; then
	# Split pipe | delimited list of ${FILTERS} into array
	FILTERS=($(tr '|' '\n' <<<"${FILTER}"))

	for filter in ${FILTERS[@]}; do
		FILTERSTRING="${FILTERSTRING} --filter-from ${ARKLONE[filterDir]}/${filter}.filter"
	done
fi

# Begin logging
arkloneLogger "${ARKLONE[log]}"

# Exit if no network routes configured
if [ -z "$(ip route)" ]; then
	echo "ERROR: No internet connection. Exiting..."
	exit 1
fi

printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

echo "Sending ${LOCALDIR}/ to ${ARKLONE[remote]}:${REMOTEDIR}/"
rclone copy "${LOCALDIR}/" "${ARKLONE[remote]}:${REMOTEDIR}/" ${FILTERSTRING} -u -v --config "${ARKLONE[rcloneConf]}" || exit $?

echo "Receiving ${ARKLONE[remote]}:${REMOTEDIR}/ to ${LOCALDIR}/"
rclone copy "${ARKLONE[remote]}:${REMOTEDIR}/" "${LOCALDIR}/" ${FILTERSTRING} -u -v --config "${ARKLONE[rcloneConf]}" || exit $?

echo "Finished cloud sync at $(date)"

