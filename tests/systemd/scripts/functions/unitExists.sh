#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/unitExists.sh"

ARKLONE[unitsDir]="/dev/shm/units"
TEST_UNIT="${ARKLONE[unitsDir]}/arkloned-test.path"

# Mock units
mkdir "${ARKLONE[unitsDir]}"

cat <<EOF >"${TEST_UNIT}"
[Path]
PathChanged=/path/to/foo
Unit=arkloned@-path-to-foo\x40path-to-bar\x40filter1\x7cfilter2\x7cfilter3.service

[Install]
WantedBy=multi-user.target
EOF

# Unit exists
unitExists "/path/to/foo" "filter3"

[ $? = 0 ] || exit 70

# Unit exists, but with different filters
FILTER_LIST=$((unitExists "/path/to/foo" "filter4") 2>&1)

# Unit does not exit with code 0
[ $? != 0 ] || exit 70

# unitExists returns expected string
[ "${FILTER_LIST}" = "filter1|filter2|filter3|filter4" ] || exit 70

# Unit does not exist
unitExists "/path/to/bar" "foo"

# Unit does not exit with code 0
[ $? != 0 ] || exit 70

# Teardown
rm -rf "${ARKLONE[unitsDir]}"


