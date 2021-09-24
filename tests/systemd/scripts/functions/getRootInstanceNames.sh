#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/getRootInstanceNames.sh"

ARKLONE[unitsDir]="/dev/shm/units"
TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

# Mock path unit
mkdir "${ARKLONE[unitsDir]}"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/foo/bar
Unit=arkloned@test.service

[Install]
WantedBy=multi-user.target
EOF

# Run function
INSTANCE_NAME=$(getRootInstanceNames)

# Check instance name
[ "${INSTANCE_NAME}" = "test " ] || exit 71

# Teardown
rm -rf "${ARKLONE[unitsDir]}"
