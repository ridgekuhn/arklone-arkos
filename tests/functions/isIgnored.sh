#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/isIgnored.sh"

# Mock dirs
ARKLONE[ignoreDir]="/dev/shm/ignores"

mkdir "${ARKLONE[ignoreDir]}"

cat <<EOF > "${ARKLONE[ignoreDir]}/test.ignore"
ignoreme
EOF

# Dir is in ignore list
isIgnored "/path/to/ignoreme" "${ARKLONE[ignoreDir]}/test.ignore"

[ $? = 0 ] || exit 70

# Dir is not in ignore list
isIgnored "/path/to/foo" "${ARKLONE[ignoreDir]}/test.ignore"

[ $? != 0 ] || exit 70

# Teardown
rm -rf "${ARKLONE[ignoreDir]}"
