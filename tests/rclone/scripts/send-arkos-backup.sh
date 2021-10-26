#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Only run if on ArkOS
if ! grep "title=" "/usr/share/plymouth/themes/text.plymouth" | grep "ArkOS"; then
    exit
fi

source "/opt/arklone/src/config.sh"

###########
# MOCK DATA
###########
# Mock test rclone.conf
ARKLONE[rcloneConf]="/dev/shm/rclone.conf"

cat <<EOF > "${ARKLONE[rcloneConf]}"
[test]
type = local
nounc = true
EOF

ARKLONE[remote]="test"

######
## RUN
######
# Run rclone in /dev/shm because remote is local filesystem
cd "/dev/shm"

# Run script
. "${ARKLONE[installDir]}/src/rclone/scripts/send-arkos-backup.sh"

[[ $? = 0 ]] || exit 70

#########
## TEST 1
#########
# Log file exists
[[ -f "/roms/backup/arkosbackup.log" ]] || exit 72

 echo "TEST 1 passed."

#########
## TEST 2
#########
# Backup file was synced
[[ -f "/dev/shm/arklone/ArkOS/arkosbackup.tar.gz" ]] || exit 72

 echo "TEST 2 passed."

###########
## TEARDOWN
###########
rm "${ARKLONE[rcloneConf]}"
rm "/roms/backup/arkosbackup.log"
rm "/roms/backup/arkosbackup.tar.gz"
rm -rf "/dev/shm/arklone"

