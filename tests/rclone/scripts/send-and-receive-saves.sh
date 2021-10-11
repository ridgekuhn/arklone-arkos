#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
LOCAL_DIR="/dev/shm/localdir"
REMOTE_DIR="/dev/shm/arklone/remotedir"

# Create some test directories and files
mkdir "${LOCAL_DIR}"
mkdir "/dev/shm/arklone"
mkdir "${REMOTE_DIR}"

touch "${LOCAL_DIR}/foo"
touch "${LOCAL_DIR}/ignoreme"
touch "${REMOTE_DIR}/bar"
touch "${REMOTE_DIR}/ignoremetoo"

# Mock filters
ARKLONE[filterDir]="/dev/shm/filters"
mkdir "${ARKLONE[filterDir]}"

touch "${ARKLONE[filterDir]}/global.filter"

cat <<EOF > "${ARKLONE[filterDir]}/test.filter"
- ignoreme
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test2.filter"
- ignoremetoo
EOF

# Mock test rclone.conf
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"

cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
nounc = true
EOF

ARKLONE[remote]="test"

#####
# RUN
#####
# Run rclone in /dev/shm because remote is local filesystem
cd "/dev/shm"

# Source script, but run in subshell so it can exit without exiting the test
(. "${ARKLONE[installDir]}/rclone/scripts/send-and-receive-saves.sh" "${LOCAL_DIR}@${REMOTE_DIR##*arklone/}@test|test2")

[ $? = 0 ] || exit 70

########
# TEST 1
########
# Log file exists
[ -f "${ARKLONE[log]}" ] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# Local test file was synced
[ -f "${REMOTE_DIR}/foo" ] || exit 72

echo "TEST 2 passed."

########
# TEST 3
########
# Remote test file was synced
[ -f "${LOCAL_DIR}/bar" ] || exit 72

echo "TEST 3 passed."

########
# TEST 4
########
# Ignored files were not synced
[ ! -z "${LOCAL_DIR}/ignoremetoo" ] || exit 74
[ ! -z "${REMOTE_DIR}/ignoreme" ] || exit 74

echo "TEST 4 passed."

##########
# TEARDOWN
##########
rm -rf "${LOCAL_DIR}"
rm -rf "/dev/shm/arklone"
rm -rf "${REMOTE_DIR}"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"
rm "${ARKLONE[log]}"
