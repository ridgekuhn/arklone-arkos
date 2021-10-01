#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

########
# TEST 1
########
# Check if config array loaded correctly
[ "${#ARKLONE[@]}" -gt 0 ] || exit 70

echo "TEST 1 passed."

