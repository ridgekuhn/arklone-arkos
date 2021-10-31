#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/rclone/scripts/functions/getFilterString.sh"

###########
# MOCK DATA
###########
ARKLONE[filterDir]="/dev/shm/filters"

mkdir "${ARKLONE[filterDir]}"
touch "${ARKLONE[filterDir]}/test.files"
touch "${ARKLONE[filterDir]}/test.exclude"
touch "${ARKLONE[filterDir]}/test.filter"
touch "${ARKLONE[filterDir]}/test.include"

########
# TEST 1
########
# All filter files concatenated correctly
FILTERS="test"

FILTER_STRING="$(getFilterString "${FILTERS}")"

CORRECT_STRING="--files-from=${ARKLONE[filterDir]}/test.files --exclude-from=${ARKLONE[filterDir]}/global.exclude --exclude-from=${ARKLONE[filterDir]}/test.exclude --filter-from=${ARKLONE[filterDir]}/test.filter --include-from=${ARKLONE[filterDir]}/test.include"

[[ "${FILTER_STRING}" = "${CORRECT_STRING}" ]] || exit 65

echo "TEST 1 passed."

########
# TEST 2
########
# No filters passed returns global exclude filter
FILTERS=""

FILTER_STRING="$(getFilterString "${FILTERS}")"

CORRECT_STRING="--exclude-from=${ARKLONE[filterDir]}/global.exclude"

[[ "${FILTER_STRING}" = "${CORRECT_STRING}" ]] || exit 65

echo "TEST 2 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[filterDir]}"

