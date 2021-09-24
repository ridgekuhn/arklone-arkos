#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

# Create test log
arkloneLogger "/dev/shm/test.log"

# Log file exists
[ -f "/dev/shm/test.log" ] || exit 73

# Teardown
rm "/dev/shm/test.log"
