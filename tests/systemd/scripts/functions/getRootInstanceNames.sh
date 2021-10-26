#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/systemd/scripts/functions/getRootInstanceNames.sh"

###########
# MOCK DATA
###########
# Mock path unit
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/foo/bar
Unit=arkloned@test.service

[Install]
WantedBy=multi-user.target
EOF

#####
# RUN
#####
INSTANCE_NAME=$(getRootInstanceNames)

########
# TEST 1
########
# Check instance name
[[ "${INSTANCE_NAME}" = "test " ]] || exit 71

echo "TEST 1 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"

