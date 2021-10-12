#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Mock rclone/scritps dir
mkdir "/dev/shm/rclone"
mkdir "/dev/shm/rclone/scripts"

# Copy sync-all-dirs.sh
# because it uses "${ARKLONE[installDir]} to call other scripts"
cp "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "/dev/shm/rclone/scripts/sync-all-dirs.sh"
chmod u+x "/dev/shm/rclone/scripts/sync-all-dirs.sh"

# Change "${ARKLONE[installDir]}"
# so we can mock other scripts called by sync-all-dirs.sh
ARKLONE[installDir]="/dev/shm"

# Mock sync-one-dir.sh
cat <<EOF >"${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"
#!/bin/bash
[ "\${1}" = "send" ] || [ "\${1}" = "receive" ] || exit 64
[ "\${2}" = "localDir@remoteDir@filter1|filter2" ] || exit 64
EOF

chmod u+x "${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"

# Mock functions called by sync-all-dirs.sh
function getRootInstanceNames() {
	echo "localDir@remoteDir@filter1|filter2"
}

########
# TEST 1
########
# Exit with error if invalid argument

# Source script, but run in subshell so it can exit with out exiting test
(. "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "foo")

[ $? = 64 ] || exit 64

echo "TEST 1 passed."

########
# TEST 2
########
# sync-one-dir.sh is called with "send"

# Source script, but run in subshell so it can exit with out exiting test
(. "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "send")
echo $?

[ $? = 0 ] || exit 1

echo "TEST 2 passed."

########
# TEST 3
########
# sync-one-dir.sh is called with "receive"

# Source script, but run in subshell so it can exit with out exiting test
(. "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "receive")

[ $? = 0 ] || exit 1

echo "TEST 3 passed"

########
# TEST 4
########
# Script exits with rclone exit code

# Mock sync-one-dir.sh
cat <<EOF >"${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"
#!/bin/bash
exit 255
EOF

chmod u+x "${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"

# Source script, but run in subshell so it can exit with out exiting test
(. "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "send")

[ $? = 255 ] || exit 70

echo "TEST 4 passed."

########
# TEST 5
########
# Script still exits with code 0
# if rclone exits with code 3 (directory not found)
# Mock sync-one-dir.sh
cat <<EOF >"${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"
#!/bin/bash
exit 3
EOF

chmod u+x "${ARKLONE[installDir]}/rclone/scripts/sync-one-dir.sh"

# Source script, but run in subshell so it can exit with out exiting test
(. "${ARKLONE[installDir]}/rclone/scripts/sync-all-dirs.sh" "send")

[ $? = 0 ] || exit 70

echo "TEST 5 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[installDir]}/rclone"

