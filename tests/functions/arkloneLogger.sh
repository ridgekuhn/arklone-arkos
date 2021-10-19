#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

#####
# RUN
#####
# Create test log
arkloneLogger "/dev/shm/test.log"

[[ $? = 0 ]] || exit $?

########
# TEST 1
########
# Log file exists
[[ -f "/dev/shm/test.log" ]] || exit 73

echo "TEST 1 passed."

##########
# TEARDOWN
##########
# Give tee time to stop writing to the log
sleep 1

rm "/dev/shm/test.log"

