#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/printMenu.sh"

# Create a test array
TESTARR=("test")

# Create a test menu string
TESTSTR=$(printMenu "${TESTARR[@]}")

# Menu item prepended by index
[ "${TESTSTR}" = "0 test " ] || exit 70
