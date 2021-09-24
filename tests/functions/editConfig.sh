#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/editConfig.sh"

# Create a test config file
cat <<EOF > "/dev/shm/test.cfg"
foo = "bar"
EOF

# Edit test config
editConfig "foo" "notBar" "/dev/shm/test.cfg"

# Config was changed successfully
TEST_SETTING=$(sed -e 's/^foo *= *"//' -e 's/" *$//' "/dev/shm/test.cfg")

[ "${TEST_SETTING}" = "notBar" ] || exit 78

# Teardown
rm "/dev/shm/test.cfg"
