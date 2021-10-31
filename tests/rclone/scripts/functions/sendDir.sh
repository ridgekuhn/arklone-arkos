#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/rclone/scripts/functions/sendDir.sh"

# Mock local directory tree
LOCAL_DIR="/dev/shm/localdir"
mkdir "${LOCAL_DIR}"
touch "${LOCAL_DIR}/test"
touch "${LOCAL_DIR}/ignoreme"
touch "${LOCAL_DIR}/ignoremetoo"
touch "${LOCAL_DIR}/ignoremethree"

# Mock remote directory tree
REMOTE_DIR="/dev/shm/arklone/remotedir"
mkdir "/dev/shm/arklone"
mkdir "${REMOTE_DIR}"

# Mock rclone filters
ARKLONE[filterDir]="/dev/shm/filters"

mkdir "${ARKLONE[filterDir]}"

cat <<EOF > "${ARKLONE[filterDir]}/global.exclude"
ignoreme
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test1.exclude"
ignoremetoo
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

sendDir "${LOCAL_DIR}" "${REMOTE_DIR##*arklone/}" "test1|test2"

[[ $? = 0 ]] || exit 70

########
# TEST 1
########
# Test file was sent
[[ -f "${REMOTE_DIR}/test" ]] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# Ignored files were not synced
[[ ! -f "${REMOTE_DIR}/ignoreme" ]] || exit 74
[[ ! -f "${REMOTE_DIR}/ignoremetoo" ]] || exit 74
[[ ! -f "${REMOTE_DIR}/ignoremethree" ]] || exit 74

echo "TEST 2 passed."

##########
# TEARDOWN
##########
rm -rf "${LOCAL_DIR}"
rm -rf "${REMOTE_DIR}"
rm -rf "/dev/shm/arklone"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"

