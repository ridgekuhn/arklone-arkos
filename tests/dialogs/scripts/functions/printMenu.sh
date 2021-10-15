#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# @todo Remove this in favor of ${!array[@]} syntax

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/dialogs/scripts/functions/printMenu.sh"

###########
# MOCK DATA
###########
TESTARR=("test")

#####
# RUN
#####
TESTSTR=$(printMenu "${TESTARR[@]}")

# Menu item prepended by index
[ "${TESTSTR}" = "0 test " ] || exit 70

echo "TEST 1 passed."
