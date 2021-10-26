#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/functions/editConfig.sh"

###########
# MOCK DATA
###########
# Create a test config file
cat <<EOF > "/dev/shm/test.cfg"
foo = "bar"
EOF

#####
# RUN
#####
# Edit test config
editConfig "foo" "notBar" "/dev/shm/test.cfg"

[[ $? = 0 ]] || exit $?

########
# TEST 1
########
# Config was changed successfully
TEST_SETTING=$(sed -e 's/^foo *= *"//' -e 's/" *$//' "/dev/shm/test.cfg")
[[ "${TEST_SETTING}" = "notBar" ]] || exit 78

echo "TEST 1 passed."

##########
# TEARDOWN
##########
rm "/dev/shm/test.cfg"

