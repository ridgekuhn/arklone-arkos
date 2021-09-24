#!/bin/bash
# arklone cloud sync on boot
# by ridgek
# @todo only source if doesn't exist
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t arkloneLogger)" = "function" ] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"
[ "$(type -t getRootInstanceNames)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

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
	IFS="@" read -r LOCALDIR REMOTEDIR FILTERS <<< "${instance}"

	FILTERSTRING="--filter-from ${ARKLONE[filterDir]}/global.filter"

	# Append unit-specific filters if specified
	if [ ! -z "${FILTERS}" ]; then
		# Split pipe | delimited list of ${FILTERS} into array
		FILTERS=($(tr '|' '\n' <<<"${FILTER}"))

		for filter in ${FILTERS[@]}; do
			FILTERSTRING="${FILTERSTRING} --filter-from ${ARKLONE[filterDir]}/${filter}.filter"
		done
	fi

	rcloneExitCode=0

	printf "\n======================================================\n"
	echo "Started new cloud sync at $(date)"
	echo "------------------------------------------------------"

	echo "Receiving ${ARKLONE[remote]}:${REMOTEDIR}/ to ${LOCALDIR}/"
	rclone copy "${ARKLONE[remote]}:${REMOTEDIR}/" "${LOCALDIR}/" ${filterstring} -u -v --config "${ARKLONE[rcloneConf]}"

	rcloneExitCode=$?

	# Record non-zero exit code if any instance fails to sync
	if [ "${rcloneExitCode}" != 0 ]; then
		exitCode="${rcloneExitCode}"
	fi
done

exit $exitCode
