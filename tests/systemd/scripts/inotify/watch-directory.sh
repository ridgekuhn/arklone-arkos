#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"

###########
# MOCK DATA
###########
TEST_FILE="/dev/shm/helloworld"

TEST_DIR="/dev/shm/testdir"
mkdir "${TEST_DIR}"

mkdir "/dev/shm/src"
ARKLONE[unitsDir]="/dev/shm/src/units"
mkdir "${ARKLONE[unitsDir]}"

cat <<EOF >"${ARKLONE[unitsDir]}/arkloned-test.path"
PathChanged=${TEST_DIR}
Unit=arkloned-test.service
EOF

cat <<EOF >"${ARKLONE[unitsDir]}/arkloned-test.service"
[Service]
Type=oneshot
UMask=000
ExecStart=/bin/bash -c 'touch "${TEST_FILE}"'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl link "${ARKLONE[unitsDir]}/arkloned-test.service"

#####
# RUN
#####
. "${ARKLONE[installDir]}/src/systemd/scripts/inotify/watch-directory.sh" "${ARKLONE[unitsDir]}/arkloned-test.path" &

PID=$!

# Wait for service to activate
sleep 1

echo "hello world" > "${TEST_DIR}/helloworld"

# Wait for service to run ExecStart=
sleep 1

# Partial teardown in case tests fail
kill $PID
sudo systemctl disable "arkloned-test.service"

########
# TEST 1
########
[[ -f "${TEST_FILE}" ]] || exit 72

echo "TEST 1 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"
rm -rf "/dev/shm/src"
sudo rm "${TEST_FILE}"
rm -rf "${TEST_DIR}"

