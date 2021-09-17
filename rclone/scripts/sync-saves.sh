#!/bin/bash
# rclone cloud syncing for ArkOS
# by ridgek
#
# @param $1 {string} directory paths in format: "sourceDir@targetDir@filterFile"
#
#	@usage
#		${ARKLONE_DIR}/rclone/scripts/sync-saves.sh "/roms@retroarch/roms"
########
# CONFIG
########
source "./config.sh"

#########
# HELPERS
#########
source "${ARKLONE_DIR}/rclone/scripts/helpers/logger.sh"

###########
# PREFLIGHT
###########
IFS="@" read -r LOCALDIR REMOTEDIR FILTER <<< "${1}"
LOG_FILE="${BACKUP_DIR}/arklone/arklone-saves.log"

logger "${LOG_FILE}"

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
FILTERSTRING="--filter-from ${ARKLONE_DIR}/rclone/filters/global.filter"
# Append unit-specific filters if specified
if [ ! -z "${FILTER}" ]; then
	FILTERSTRING="${FILTERSTRING} --filter-from ${ARKLONE_DIR}/rclone/filters/${FILTER}.filter"
fi

echo "Sending ${LOCALDIR}/ to ${REMOTE_CURRENT}:${REMOTEDIR}/"
rclone copy "${LOCALDIR}/" "${REMOTE_CURRENT}:${REMOTEDIR}/" ${FILTERSTRING} -u -v || exit $?

echo "Receiving ${REMOTE_CURRENT}:${REMOTEDIR}/ to ${LOCALDIR}/"
rclone copy "${REMOTE_CURRENT}:${REMOTEDIR}/" "${LOCALDIR}/" ${FILTERSTRING} -u -v || exit $?

##########
# TEARDOWN
##########
echo "Finished cloud sync at $(date)"
