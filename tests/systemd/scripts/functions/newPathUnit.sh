#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"

ARKLONE[unitsDir]="/dev/shm/units"
TEST_UNIT="${ARKLONE[unitsDir]}/test.path"

# Mock units
mkdir "${ARKLONE[unitsDir]}"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/path/to/foo
Unit=arkloned@-path-to-foo\\x40path-to-bar\\x40filter1\\x7cfilter2\\x7cfilter3.service

[Install]
WantedBy=multi-user.target
EOF

# Unit exists
unitExists "/path/to/foo" "filter3"

[ $? = 0 ] || exit 70

# Unit exists, but with different filters
FILTER_LIST=$(unitExists "/path/to/foo" "filter4")

[ $? != 0 ] || exit 70

[ "${FILTER_LIST}" = "filter1|filter2|filter3|filter4" ]

# Unit does not exist
unitExists "/path/to/bar"

[ $? != 0 ] || exit 70

# Teardown
rm "${TEST_UNIT}"

# Create new path unit
LOCAL_DIR="/path/to/foo"
REMOTE_DIR="path/to/bar"
FILTER="filter1"

newPathUnit "test" "${LOCAL_DIR}" "${REMOTE_DIR}" "${FILTER}"

# Unit exists
[ -f "${TEST_UNIT}" ] || exit 72

# Unit has correct PathChanged
[ "$(cat "${TEST_UNIT}" | sed -e 's/^PathChanged=//')" = "${LOCAL_DIR}" ] || exit 78

# Unit has correct instance name
INSTANCE_NAME=$(systemd-escape "${LOCAL_DIR}@${REMOTE_DIR}@${FILTER}")

[ "$(cat "${TEST_UNIT}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')" = "${INSTANCE_NAME}" ] || exit 78

# Teardown
rm -rf "${ARKLONE[unitsDir]}"
