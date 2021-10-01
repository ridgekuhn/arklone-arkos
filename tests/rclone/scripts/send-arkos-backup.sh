#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Create some test directories and files
ARKLONE[backupDir]="/dev/shm/backup"
mkdir "${ARKLONE[backupDir]}"

touch "${ARKLONE[backupDir]}/arkosbackup.tar.gz"

# Mock test rclone.conf
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"

cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
nounc = true
EOF

# @todo where does rclone write to when remote is local
# 	and remote is passed like remote:someDir/ ?
######
## RUN
######
## Run script
#. "${ARKLONE[installDir]}/rclone/send-arkos-backup.sh"
#
#[ $? = 0 ] || exit 70
#
#########
## TEST 1
#########
## Log file exists
#[ -f "${ARKLONE[backupDir]}/arkosbackup.log" ] || exit 72
#
# echo "TEST 1 passed."
#
#########
## TEST 2
#########
## Backup file was synced
#[ -d "?" ] || exit 72
#[ -f "?/arkosbackup.tar.gz" ] || exit 72
#
# echo "TEST 2 passed."
#
###########
## TEARDOWN
###########
#rm -rf "${ARKLONE[backupDir]}"
#rm "${ARKLONE[rcloneConf]}"

