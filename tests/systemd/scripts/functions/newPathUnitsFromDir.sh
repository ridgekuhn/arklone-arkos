#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnitsFromDir.sh"

###########
# MOCK DATA
###########
# Mock units dir
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

# Mock ignore files
ARKLONE[ignoreDir]="/dev/shm/ignores"
mkdir "${ARKLONE[ignoreDir]}"

cat <<EOF > "${ARKLONE[ignoreDir]}/global.ignore"
ignoreme
EOF

cat <<EOF > "${ARKLONE[ignoreDir]}/test.ignore"
ignoremetoo
EOF

# Mock directory tree
SAVES_DIR="/dev/shm/saves"

mkdir "${SAVES_DIR}"
mkdir "${SAVES_DIR}/ignoreme"
mkdir "${SAVES_DIR}/nes"
mkdir "${SAVES_DIR}/nes/FCEUmm"
mkdir "${SAVES_DIR}/nes/ignoremetoo"
mkdir "${SAVES_DIR}/snes"
mkdir "${SAVES_DIR}/snes/bsnes"

########
# TEST 1
########
# Make depth 1 path units
newPathUnitsFromDir "${SAVES_DIR}" "remotedir" 1 true "filter" "${ARKLONE[ignoreDir]}/test.ignore"

[ $? = 0 ] || exit $?

# Units exist
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes.sub.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes.sub.auto.path" ] || exit 72

echo "TEST 1A passed."

# Ignored units do not exit
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-ignoreme.sub.auto.path" ] || exit 70

echo "TEST 1B passed."

# Depth 1 units do not exit
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-fceumm.sub.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-ignoremetoo.sub.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-bsnes.sub.auto.path" ] || exit 70

echo "TEST 1C passed."

# Reset units dir
rm "${ARKLONE[unitsDir]}/"*".path"

########
# TEST 2
########
# Make depth 2 path units, no root unit
newPathUnitsFromDir "${SAVES_DIR}" "remotedir" 2 false "filter" "${ARKLONE[ignoreDir]}/test.ignore"

[ $? = 0 ] || exit $?

# Units exit
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-FCEUmm.sub.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes-bsnes.sub.auto.path" ] || exit 72

echo "TEST 2A passed."

# Ignored units do not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-ignoremetoo.sub.auto.path" ] || exit 70

echo "TEST 2B passed."

# Root unit does not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir.auto.path" ] || exit 70

echo "TEST 2C passed."

# Depth 0 units do not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-ignoreme.auto.path" ] || exit 70

echo "TEST 2D passed."

# Instance name is correct
INSTANCE_NAME="$(grep "Unit=" "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-FCEUmm.sub.auto.path" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')"
INSTANCE_NAME="$(systemd-escape -u -- "${INSTANCE_NAME}")"

[ "${INSTANCE_NAME}" = "${SAVES_DIR}/nes/FCEUmm@remotedir/nes/FCEUmm@filter" ] || exit 78

echo "TEST 2E passed."

##########
# TEARDOWN
##########
rm -rf "${ARKLONE[unitsDir]}"
rm -rf "${ARKLONE[ignoreDir]}"
rm -rf "${SAVES_DIR}"

