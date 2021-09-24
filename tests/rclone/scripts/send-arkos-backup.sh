#!/bin/bash
source "/opt/arklone/config.sh"

ARKLONE[backupDir]="/dev/shm/backup"
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"

# Create some test directories and files
mkdir "${ARKLONE[backupDir]}"

touch "${ARKLONE[backupDir]}/arkosbackup.tar.gz"

# Mock test rclone.conf
cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
nounc = true
EOF

# @todo where does rclone write to when remote is local
# 	and remote is passed like remote:someDir/ ?
## Run script
#. "${ARKLONE[installDir]}/rclone/send-arkos-backup.sh"
#
## Check exit code
#[ $? = 0 ] || exit 70
#
## Log file exists
#[ -f "${ARKLONE[backupDir]}/arkosbackup.log" ] || exit 72
#
## Backup file was synced
#[ -d "?" ] || exit 72
#[ -f "?/arkosbackup.tar.gz" ] || exit 72
