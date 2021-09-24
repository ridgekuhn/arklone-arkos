#!/bin/bash
source "/opt/arklone/config.sh"

LOCAL_DIR="/dev/shm/localdir"
REMOTE_DIR="/dev/shm/remotedir"
ARKLONE[filterDir]="/dev/shm/filters"
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"
ARKLONE[remote]="test"

# Create some test directories and files
mkdir "${LOCAL_DIR}"
mkdir "${REMOTE_DIR}"

touch "${LOCAL_DIR}/foo"
touch "${LOCAL_DIR}/ignoreme"
touch "${REMOTE_DIR}/bar"
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
. "${ARKLONE[installDir]}/rclone/scripts/send-and-receive-saves.sh" "${LOCAL_DIR}@${REMOTE_DIR}@test|test2"

# Check exit code
[ $? = 0 ] || exit 70

# Log file exists
[ -f "${ARKLONE[log]}" ] || exit 72

# Local test file was synced
[ -f "${REMOTE_DIR}/foo" ] || exit 72

# Remote test file was synced
[ -f "${LOCAL_DIR}/bar" ] || exit 72

# Ignored files were not synced
[ ! -z "${LOCAL_DIR}/ignoremetoo" ] || exit 74
[ ! -z "${REMOTE_DIR}/ignoreme" ] || exit 74

# Teardown
rm -rf "${LOCAL_DIR}"
rm -rf "${REMOTE_DIR}"
rm -rf "${ARKLONE[filterDir]}"
rm "${ARKLONE[rcloneConf]}"
