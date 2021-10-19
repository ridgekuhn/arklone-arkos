#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/unitExists.sh"

###########
# MOCK DATA
###########
# Mock units
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/path/to/foo
Unit=arkloned@-path-to-foo\x40path-to-bar\x40filter1\x7cfilter2\x7cfilter3.service

[Install]
WantedBy=multi-user.target
EOF

#####
# RUN
#####
unitExists "/path/to/foo" "filter3"

[[ $? = 0 ]] || exit 70

########
# TEST 1
########
# Unit exists, but with different filters
FILTER_LIST=$((unitExists "/path/to/foo" "filter4") 2>&1)

[[ $? != 0 ]] || exit 70

echo "TEST 1 passed."

########
# TEST 2
########
# unitExists returns expected string
[[ "${FILTER_LIST}" = "filter1|filter2|filter3|filter4" ]] || exit 70

echo "TEST 2 passed."

########
# TEST 3
########
# Unit does not exist
unitExists "/path/to/bar" "foo"

[[ $? != 0 ]] || exit 70

echo "TEST 3 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"

