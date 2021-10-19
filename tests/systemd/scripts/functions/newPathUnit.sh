#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"

###########
# MOCK DATA
###########
# Mock ${ARKLONE[unitsDir]}
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

LOCAL_DIR="/path/to/foo"
REMOTE_DIR="path/to/bar"
FILTER="filter1"

#####
# RUN
#####
newPathUnit "test" "${LOCAL_DIR}" "${REMOTE_DIR}" "${FILTER}"

[[ $? = 0 ]] || exit $?

TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

########
# TEST 1
########
# Unit exists
[[ -f "${TEST_UNIT}" ]] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# Unit has correct PathChanged
[[ $(grep "PathChanged=" "${TEST_UNIT}" | sed -e 's/^PathChanged=//') = "${LOCAL_DIR}" ]] || exit 78

echo "TEST 2 passed."

########
# TEST 3
########
# Unit has correct instance name
INSTANCE_NAME=$(systemd-escape "${LOCAL_DIR}@${REMOTE_DIR}@${FILTER}")

[[ $(grep "Unit=" "${TEST_UNIT}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//') = "${INSTANCE_NAME}" ]] || exit 78

echo "TEST 3 passed."

########
# TEST 4
########
# Attempt to create a new unit, and modify the existing unit's filter
newPathUnit "test" "${LOCAL_DIR}" "${REMOTE_DIR}" "filter2"

INSTANCE_NAME=$(systemd-escape "${LOCAL_DIR}@${REMOTE_DIR}@filter1|filter2")

[[ $(grep "Unit=" "${TEST_UNIT}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//') = "${INSTANCE_NAME}" ]] || exit 78

echo "TEST 4 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"

