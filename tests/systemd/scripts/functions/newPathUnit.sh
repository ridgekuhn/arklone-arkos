#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"

# Mock ${ARKLONE[unitsDir]}
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

# Create new path unit
TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

LOCAL_DIR="/path/to/foo"
REMOTE_DIR="path/to/bar"
FILTER="filter1"

newPathUnit "test" "${LOCAL_DIR}" "${REMOTE_DIR}" "${FILTER}"

# Unit exists
[ -f "${TEST_UNIT}" ] || exit 72

# Unit has correct PathChanged
[ $(grep "PathChanged=" "${TEST_UNIT}" | sed -e 's/^PathChanged=//') = "${LOCAL_DIR}" ] || exit 78

# Unit has correct instance name
INSTANCE_NAME=$(systemd-escape "${LOCAL_DIR}@${REMOTE_DIR}@${FILTER}")

[ $(grep "Unit=" "${TEST_UNIT}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//') = "${INSTANCE_NAME}" ] || exit 78

# Modify path unit's filter
newPathUnit "test" "${LOCAL_DIR}" "${REMOTE_DIR}" "filter2"

INSTANCE_NAME=$(systemd-escape "${LOCAL_DIR}@${REMOTE_DIR}@filter1|filter2")

[ $(grep "Unit=" "${TEST_UNIT}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//') = "${INSTANCE_NAME}" ] || exit 78


# Teardown
rm -rf "${ARKLONE[unitsDir]}"
