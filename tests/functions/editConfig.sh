#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/functions/editConfig.sh"

###########
# MOCK DATA
###########
TEST_CFG="/dev/shm/test.cfg"

# Create a test config file
cat <<EOF > "${TEST_CFG}"
foo = "bar"
ballsacks   =
EOF

########
# TEST 1
########
# Config was changed successfully
editConfig "foo" "notBar" "${TEST_CFG}"

TEST_SETTING=$(grep "foo =" "${TEST_CFG}" | sed -e 's/^foo = "//' -e 's/"$//')
[[ "${TEST_SETTING}" = "notBar" ]] || exit 78

echo "TEST 1 passed."

########
# TEST 2
########
# Option was commented successfully
editConfig "foo" "bar" true "${TEST_CFG}"

if ! grep '# foo = "bar"' "${TEST_CFG}" >/dev/null 2>&1; then
    exit 70
fi

echo "TEST 2 passed."

########
# TEST 3
########
# Non-existent option was added
editConfig "newOption" "baz" "${TEST_CFG}"

if ! grep -E 'newOption = "baz"' "${TEST_CFG}" >/dev/null 2>&1; then
    exit 70
fi

echo "TEST 3 passed."

##########
# TEARDOWN
##########
rm "${TEST_CFG}"

