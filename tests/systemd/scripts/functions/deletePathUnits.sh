#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/deletePathUnits.sh"

###########
# MOCK DATA
###########
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

#####
# RUN
#####
deletePathUnits "${TEST_UNIT}"

[ $? = 0 ] || exit $?

########
# TEST 1
########
# Unit should not be listed in systemd
if systemctl list-unit-files "${TEST_UNIT##*/}" | grep "${TEST_UNIT##*/}"; then
	exit 78
fi

echo "TEST 1 passed."

########
# TEST 2
########
# Unit file should be deleted
[ ! -f "${TEST_UNIT}" ] || exit 70

echo "TEST 2 passed."

##########
# TEARDOWN
##########
rm -rf "${UNITS_DIR}"

