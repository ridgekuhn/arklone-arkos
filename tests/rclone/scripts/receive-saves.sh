#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
LOCAL_DIR="/dev/shm/localdir"
REMOTE_DIR="/dev/shm/remotedir"

# Create some test directories and files
mkdir "${LOCAL_DIR}"
mkdir "${REMOTE_DIR}"

touch "${REMOTE_DIR}/test"
touch "${REMOTE_DIR}/ignoreme"
touch "${REMOTE_DIR}/ignoremetoo"

# Mock getRootInstanceNames()
function getRootInstanceNames() {
	echo "${LOCAL_DIR}@${REMOTE_DIR}@test|test2"
}

# Mock filters
ARKLONE[filterDir]="/dev/shm/filters"
mkdir "${ARKLONE[filterDir]}"

touch "${ARKLONE[filterDir]}/global.filter"

cat <<EOF > "${ARKLONE[filterDir]}/test.filter"
ignoreme
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test2.filter"
ignoremetoo
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
. "${ARKLONE[installDir]}/rclone/scripts/receive-saves.sh"

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
# Test file was synced
[ -f "${LOCAL_DIR}/test" ] || exit 72

echo "TEST 2 passed."

########
# TEST 3
########
# Ignored files were not synced
[ ! -f "${LOCAL_DIR}/ignoreme" ] || exit 74
[ ! -f "${LOCAL_DIR}/ignoremetoo" ] || exit 74

echo "TEST 3 passed."

##########
# TEARDOWN
##########
rm -rf "${LOCAL_DIR}"
rm -rf "${REMOTE_DIR}"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"

