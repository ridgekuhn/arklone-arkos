#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/getEnabledUnits.sh"

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

sudo systemctl enable "${TEST_UNIT}"

#####
# RUN
#####
ENABLED_UNITS=$(getEnabledUnits)

########
# TEST 1
########
[ ! -z "${ENABLED_UNITS}" ] || exit 71

echo "TEST 1 passed."

##########
# TEARDOWN
##########
sudo systemctl disable "$(basename "${TEST_UNIT}")" || exit 1

rm -rf "${ARKLONE[unitsDir]}"
