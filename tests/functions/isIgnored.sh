#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/isIgnored.sh"

###########
# MOCK DATA
###########
ARKLONE[ignoreDir]="/dev/shm/ignores"
mkdir "${ARKLONE[ignoreDir]}"

cat <<EOF > "${ARKLONE[ignoreDir]}/test.ignore"
ignoreme
EOF

########
# TEST 1
########
# Dir is in ignore list
isIgnored "/path/to/ignoreme" "${ARKLONE[ignoreDir]}/test.ignore"

[[ $? = 0 ]] || exit 70

echo "TEST 1 passed."

########
# TEST 2
########
# Dir is not in ignore list
isIgnored "/path/to/foo" "${ARKLONE[ignoreDir]}/test.ignore"

[[ $? != 0 ]] || exit 70

echo "TEST 2 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[ignoreDir]}"

