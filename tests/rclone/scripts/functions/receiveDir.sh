#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/rclone/scripts/functions/receiveDir.sh"

# Mock local directory tree
LOCAL_DIR="/dev/shm/localdir"
mkdir "${LOCAL_DIR}"

# Mock remote directory tree
REMOTE_DIR="/dev/shm/arklone/remotedir"
mkdir "/dev/shm/arklone"
mkdir "${REMOTE_DIR}"
touch "${REMOTE_DIR}/test"
touch "${REMOTE_DIR}/ignoreme"
touch "${REMOTE_DIR}/ignoremetoo"
touch "${REMOTE_DIR}/ignoremethree"

# Mock rclone filters
ARKLONE[filterDir]="/dev/shm/filters"
mkdir "${ARKLONE[filterDir]}"

cat <<EOF > "${ARKLONE[filterDir]}/global.filter"
- ignoreme
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test1.filter"
- ignoremetoo
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test2.filter"
- ignoremethree
EOF

# Mock rclone.conf
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"

cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
EOF

ARKLONE[remote]="test"

#####
# RUN
#####
# Run rclone in /dev/shm because remote is local filesystem
cd "/dev/shm"

receiveDir "${LOCAL_DIR}" "${REMOTE_DIR##*arklone/}" "test1|test2"

[[ $? = 0 ]] || exit 70

########
# TEST 1
########
# Test file was received
[[ -f "${LOCAL_DIR}/test" ]] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# Ignored files were not synced
[[ ! -f "${LOCAL_DIR}/ignoreme" ]] || exit 74
[[ ! -f "${LOCAL_DIR}/ignoremetoo" ]] || exit 74
[[ ! -f "${LOCAL_DIR}/ignoremethree" ]] || exit 74

echo "TEST 2 passed."

##########
# TEARDOWN
##########
rm -rf "${LOCAL_DIR}"
rm -rf "${REMOTE_DIR}"
rm -rf "/dev/shm/arklone"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"

