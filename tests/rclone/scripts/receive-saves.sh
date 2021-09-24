#!/bin/bash
source "/opt/arklone/config.sh"

LOCAL_DIR="/dev/shm/localdir"
REMOTE_DIR="/dev/shm/remotedir"
ARKLONE[filterDir]="/dev/shm/filters"
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"
ARKLONE[remote]="test"

# Mock getRootInstanceNames()
function getRootInstanceNames() {
	echo "${LOCAL_DIR}@${REMOTE_DIR}@test|test2"
}

# Create some test directories and files
mkdir "${LOCAL_DIR}"
mkdir "${REMOTE_DIR}"

touch "${REMOTE_DIR}/test"
touch "${REMOTE_DIR}/ignoreme"
touch "${REMOTE_DIR}/ignoremetoo"

# Mock ${ARKLONE[filterDir]}
mkdir "${ARKLONE[filterDir]}"

# Mock filters
touch "${ARKLONE[filterDir]}/global.filter"

cat <<EOF > "${ARKLONE[filterDir]}/test.filter"
ignoreme
EOF

cat <<EOF > "${ARKLONE[filterDir]}/test2.filter"
ignoremetoo
EOF

# Mock test rclone.conf
cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
nounc = true
EOF

# Run script
. "${ARKLONE[installDir]}/rclone/scripts/receive-saves.sh"

# Check exit code
[ $? = 0 ] || exit 70

# Log file exists
[ -f "${ARKLONE[log]}" ] || exit 72

# Test file was synced
[ -f "${LOCAL_DIR}/test" ] || exit 72

# Ignored files were not synced
[ ! -f "${LOCAL_DIR}/ignoreme" ] || exit 74
[ ! -f "${LOCAL_DIR}/ignoremetoo" ] || exit 74

# Teardown
rm -rf "${LOCAL_DIR}"
rm -rf "${REMOTE_DIR}"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"
