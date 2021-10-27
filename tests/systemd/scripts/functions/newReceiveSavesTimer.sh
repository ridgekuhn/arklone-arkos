#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/systemd/scripts/functions/newReceiveSavesTimer.sh"

###########
# MOCK DATA
###########
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

#####
# RUN
#####
newReceiveSavesTimer "60"

########
# TEST 1
########
# arkloned-receive-saves.timer exists
[[ -f  "${ARKLONE[unitsDir]}/arkloned-receive-saves.timer" ]] || exit 72

echo "TEST 1 passed."

########
# TEST 2
########
# Post-boot timer is correct
if ! grep "OnBootSec=60" "${ARKLONE[unitsDir]}/arkloned-receive-saves.timer"; then
    exit 70
fi

echo "TEST 2 passed."

########
# TEST 3
########
# Unit reactivate timer is correct
if ! grep "OnUnitActiveSec=60" "${ARKLONE[unitsDir]}/arkloned-receive-saves.timer"; then
    exit 70
fi

echo "TEST 3 passed."

########
# TEST 4
########
# Unit does not exist if 0 seconds passed as argument
newReceiveSavesTimer "0"

[[ ! -f  "${ARKLONE[unitsDir]}/arkloned-receive-saves.timer" ]] || exit 70

echo "TEST 4 passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"

