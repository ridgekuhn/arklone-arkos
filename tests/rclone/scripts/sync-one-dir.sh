#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"

###########
# MOCK DATA
###########
function sendDir() {
    [[ "${1}" = "localDir" ]] || return 64
    [[ "${2}" = "remoteDir" ]] || return 64
    [[ "${3}" = "test1|test2" ]] || return 64
}

function receiveDir() {
    [[ "${1}" = "localDir" ]] || return 64
    [[ "${2}" = "remoteDir" ]] || return 64
    [[ "${3}" = "test1|test2" ]] || return 64
}

function arkloneLogger() {
    touch "${ARKLONE[log]}"
}

########
# TEST 1
########
# Script was called with invalid sync argument

# Source script, but run in subshell so it can exit without exiting the test
(. "${ARKLONE[installDir]}/src/rclone/scripts/sync-one-dir.sh" "foo" "localDir@remoteDir@test1|test2")

[[ $? = 64 ]] || exit 64

echo "TEST 1 passed."

########
# TEST 2
########
# Script was called with malformed instance name

# Source script, but run in subshell so it can exit without exiting the test
(. "${ARKLONE[installDir]}/src/rclone/scripts/sync-one-dir.sh" "receive" "localDir40remoteDir40test1|test2")

[[ $? = 64 ]] || exit 64

echo "TEST 2 passed."

########
# TEST 3
########
# Script was called with "send"

# Source script, but run in subshell so it can exit without exiting the test
(. "${ARKLONE[installDir]}/src/rclone/scripts/sync-one-dir.sh" "send" "localDir@remoteDir@test1|test2" 1>/dev/null)

[[ $? = 0 ]] || exit 64

echo "TEST 3 passed."

########
# TEST 4
########
# Script was called with "receive"

# Source script, but run in subshell so it can exit without exiting the test
(. "${ARKLONE[installDir]}/src/rclone/scripts/sync-one-dir.sh" "receive" "localDir@remoteDir@test1|test2" 1>/dev/null)

[[ $? = 0 ]] || exit 64

echo "TEST 4 passed."

########
# TEST 5
########
# Log file exists
[[ -f "${ARKLONE[log]}" ]] || exit 72

echo "TEST 5 passed."

##########
# TEARDOWN
##########
rm "${ARKLONE[log]}"

