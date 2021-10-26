#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/rclone/scripts/functions/getFilterString.sh"

#####
# RUN
#####
FILTER_STRING="$(getFilterString "filter1|filter2")"

########
# TEST 1
########
[[ "${FILTER_STRING}" = "--filter-from ${ARKLONE[filterDir]}/global.filter --filter-from ${ARKLONE[filterDir]}/filter1.filter --filter-from ${ARKLONE[filterDir]}/filter2.filter" ]] || exit 65

