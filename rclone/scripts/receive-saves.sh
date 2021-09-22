#!/bin/bash
# arklone cloud sync on boot
# by ridgek
# @todo only source if doesn't exist
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

#############
# CONTROLLERS
#############
# Receive new save data from the cloud
#
# Only receives data and does not send anything back, so that
# the cloud copy is the correct and canonical version.
#
# Syncs "root" path unit instances only,
# since rclone will sync all subdirectories,
# and *.sub.auto.path units only exist
# because systemd path units can't watch subdirectories.
#
# @see systemd/scripts/functions/getRootInstanceNames.sh
# @see systemd/scripts/generate-retroarch-units.sh
#
# @returns rclone exit code
INSTANCES=($(getRootInstanceNames))
EXIT_CODE=0

arkloneLogger "${ARKLONE[log]}"

for instance in ${INSTANCES[@]}; do
	# Read paths from instance name
	localdir remote dir filter
	IFS="@" read -r localdir remotedir filter <<< "${instance}"

	# Set global filter file
	filterstring="--filter-from ${ARKLONE[installDir]}/rclone/filters/global.filter"

	# Append unit-specific filter file (if specified in the instance name)
	if [ ! -z "${filter}" ]; then
		filterstring="${filterstring} --filter-from ${ARKLONE[installDir]}/rclone/filters/${filter}.filter"
	fi

	rcloneExitCode=0

	printf "\n======================================================\n"
	echo "Started new cloud sync at $(date)"
	echo "------------------------------------------------------"

	echo "Receiving ${ARKLONE[remote]}:${remotedir}/ to ${localdir}/"
	rclone copy "${ARKLONE[remote]}:${remotedir}/" "${localdir}/" ${filterstring} -u -v --config "${ARKLONE[rcloneConf]}"

	rcloneExitCode=$?

	# Record non-zero exit code if any instance fails to sync
	if [ "${rcloneExitCode}" != 0 ]; then
		exitCode="${rcloneExitCode}"
	fi
done

exit $exitCode
