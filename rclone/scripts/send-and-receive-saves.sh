#!/bin/bash
# rclone cloud syncing for ArkOS
# by ridgek
#
# @param $1 {string} directory paths in format: "${localDir}@${remoteDir}@${filter}
#		${localDir} should be absolute path, no trailing slash
#		${remoteDir} no opening or trailing slashes
#		${filter} name from file in ${ARKLONE[installDir]}/rclone/filters,
#			no leading directory path or .filter extension
#
#	@usage
#		${ARKLONE[installDir]}/rclone/scripts/sync-saves.sh "/roms@retroarch/roms"
########
# CONFIG
########
source "/opt/arklone/config.sh"

#########
# HELPERS
#########
source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

###########
# PREFLIGHT
###########
IFS="@" read -r LOCALDIR REMOTEDIR FILTER <<< "${1}"

arkloneLogger "${ARKLONE[log]}"

printf "\n======================================================\n"
echo "Started new cloud sync at $(date)"
echo "------------------------------------------------------"

# Exit if no network routes configured
if [ -z "$(ip route)" ]; then
	echo "ERROR: No internet connection. Exiting..."
	exit 1
fi

#########################
# SYNC SAVEFILES TO CLOUD
#########################
FILTERSTRING="--filter-from ${ARKLONE[installDir]}/rclone/filters/global.filter"
# Append unit-specific filters if specified
if [ ! -z "${FILTER}" ]; then
	FILTERSTRING="${FILTERSTRING} --filter-from ${ARKLONE[installDir]}/rclone/filters/${FILTER}.filter"
fi

echo "Sending ${LOCALDIR}/ to ${ARKLONE[remote]}:${REMOTEDIR}/"
rclone copy "${LOCALDIR}/" "${ARKLONE[remote]}:${REMOTEDIR}/" ${FILTERSTRING} -u -v --config "${ARKLONE[rcloneConf]}" || exit $?

echo "Receiving ${ARKLONE[remote]}:${REMOTEDIR}/ to ${LOCALDIR}/"
rclone copy "${ARKLONE[remote]}:${REMOTEDIR}/" "${LOCALDIR}/" ${FILTERSTRING} -u -v --config "${ARKLONE[rcloneConf]}" || exit $?

##########
# TEARDOWN
##########
echo "Finished cloud sync at $(date)"
