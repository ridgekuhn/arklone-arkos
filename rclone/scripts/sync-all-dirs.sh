#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Sync all "root" path units
#
# Does not sync *.sub.auto.path units
# since rclone is capable of syncing recursively,
# and *.sub.auto.path units only exist
# because systemd path units can't watch subdirectories.
#
# @see systemd/scripts/functions/getRootInstanceNames.sh
# @see systemd/scripts/generate-retroarch-units.sh
#
# @param $1 {string} "send" or "receive"
#
# @returns rclone exit code

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"
[[ "$(type -t getRootInstanceNames)" = "function" ]] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

# Exit if argument is invalid
[[ "${1}" = "send" ]] || [[ "${1}" = "receive" ]] || exit 64

SYNC_TYPE="${1}"

INSTANCES=($(getRootInstanceNames))
EXIT_CODE=0

for instance in ${INSTANCES[@]}; do
    # Source the script in a subshell so it can exit without exiting this script
    (. ${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh ${SYNC_TYPE} ${instance})

    rcloneExitCode=$?

    # Record non-zero exit code if any instance fails to sync,
    # except exit code 3 (directory not found)
    # because it doesn't matter if we can't receive a directory
    # that doesn't exist on the remote
    # @see https://rclone.org/docs/#exit-code
    if
        [[ "${rcloneExitCode}" != 0 ]] \
        && [[ "${rcloneExitCode}" != 3 ]]; then
        EXIT_CODE="${rcloneExitCode}"
    fi
done

exit $EXIT_CODE

