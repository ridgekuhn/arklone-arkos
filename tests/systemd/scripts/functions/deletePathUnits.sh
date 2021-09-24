#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/deletePathUnits.sh"

UNITS_DIR="/dev/shm/units"
TEST_UNIT="${UNITS_DIR}/test.path"

# Mock path unit
mkdir "${UNITS_DIR}"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/foo/bar
Unit=arkloned@test.service

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable "${TEST_UNIT}"

# Run deletePathUnits()
deletePathUnits "${TEST_UNIT}"

# Unit should not be listed in systemd
if systemctl list-unit-files "${TEST_UNIT##*/}" | grep "${TEST_UNIT##*/}"; then
	exit 78
fi

# Unit file should be deleted
[ ! -f "${TEST_UNIT}" ] || exit 70

# Teardown
rm -rf "${UNITS_DIR}"
