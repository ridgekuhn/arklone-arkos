#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
TEST_FILE="/dev/shm/helloworld"

TEST_DIR="/dev/shm/testdir"
mkdir "${TEST_DIR}"

ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

cat <<EOF >"${ARKLONE[unitsDir]}/arkloned-test.path"
PathChanged=${TEST_DIR}
Unit=arkloned-test.service
EOF

cat <<EOF >"${ARKLONE[unitsDir]}/arkloned-test.service"
[Service]
Type=oneshot
User=ark
Group=ark
ExecStart=/bin/bash -c 'touch "${TEST_FILE}"'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl link "${ARKLONE[unitsDir]}/arkloned-test.service"

#####
# RUN
#####
. "${ARKLONE[installDir]}/systemd/scripts/inotify/watch-directory.sh" "${ARKLONE[unitsDir]}/arkloned-test.path" &

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
[ -f "${TEST_FILE}" ] || exit 72

echo "TEST 1 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"
rm "${TEST_FILE}"
rm -rf "${TEST_DIR}"

