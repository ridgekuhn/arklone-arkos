#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

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

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t arkloneLogger)" = "function" ] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"
[ "$(type -t getRootInstanceNames)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

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
		FILTERS=($(tr '|' '\n' <<<"${FILTERS}"))

		for filter in ${FILTERS[@]}; do
			FILTERSTRING+=" --filter-from ${ARKLONE[filterDir]}/${filter}.filter"
		done
	fi

	printf "\n======================================================\n"
	echo "Started new cloud sync at $(date)"
	echo "------------------------------------------------------"

	echo "Receiving ${ARKLONE[remote]}:arklone/${REMOTEDIR}/ to ${LOCALDIR}/"
	rclone copy "${ARKLONE[remote]}:arklone/${REMOTEDIR}/" "${LOCALDIR}/" ${FILTERSTRING} -u -v --config "${ARKLONE[rcloneConf]}"

	rcloneExitCode=$?

	# Record non-zero exit code if any instance fails to sync,
	# except exit code 3 (directory not found)
	# because it doesn't matter if we can't receive a directory
	# that doesn't exist on the remote
	# @see https://rclone.org/docs/#exit-code
	if
		[ "${rcloneExitCode}" != 0 ] \
		&& [ "${rcloneExitCode}" != 3 ]; then
		EXIT_CODE="${rcloneExitCode}"
	fi
done

exit $EXIT_CODE

