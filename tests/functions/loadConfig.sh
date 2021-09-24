#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/loadConfig.sh"

# Create a test config file
cat <<EOF > "/dev/shm/test.cfg"
foo = "bar"
EOF

# Create a test config array
declare -A TESTARR

loadConfig "/dev/shm/test.cfg" TESTARR

# Check settings were loaded into array
[ "${TESTARR[foo]}" = "bar" ] || 70

# Teardown
rm "/dev/shm/test.cfg"
