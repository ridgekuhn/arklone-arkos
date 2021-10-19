#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# sync-all-dirs.sh progress gauge dialog
#
# Converts output of rclone/scripts/sync-all-dirs.sh
# to progress percentage for passing to dialog gauge
#
#	IMPORTANT!
# Before calling this script, `pipefail` must be set,
# to pass non-zero exit code from main script through pipe
#
# @usage
#		set -o pipefail
#		. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh" true \
#			| . "${ARKLONE[installDir]}/dialogs/gauges/systemd/generate-retroarch-units.sh"

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t getRootInstanceNames)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

INSTANCES=($(getRootInstanceNames))
LOCALDIRS=()

for instance in ${INSTANCES[@]}; do
    IFS="@" read -r localdir remotedir filters  <<<"${instance}"

    LOCALDIRS+=("${localdir}")

    unset localdir remotedir filters
done

while read line; do
    if grep -E "^Sending.*${ARKLONE[remote]}" <<<"${line}" >/dev/null 2>&1; then
        localdir="$(sed -e 's/^Sending //' -e "s/ to ${ARKLONE[remote]}:.*$//" <<<"${line}")"

    elif grep -E "^Receiving ${ARKLONE[remote]}" <<<"${line}" >/dev/null 2>&1; then
        localdir="$(sed -e "s/^Receiving ${ARKLONE[remote]}.* to //" -e 's|/$||' <<<"${line}")"
    fi

    for i in "${!LOCALDIRS[@]}"; do
        if [ "${LOCALDIRS[$i]}" = "${localdir}" ]; then
            echo "$(( ( $i * 100 ) / ${#LOCALDIRS[@]} ))"
        fi
    done
done | whiptail \
    --title "${ARKLONE[whiptailTitle]}" \
    --gauge "Please wait while we sync your files..." \
    16 56 \
    0

