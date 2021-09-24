#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnitsFromDir.sh"

# Mock dirs
ARKLONE[unitsDir]="/dev/shm/units"
ARKLONE[ignoreDir]="/dev/shm/ignores"

mkdir "${ARKLONE[unitsDir]}"
mkdir "${ARKLONE[ignoreDir]}"

cat <<EOF > "${ARKLONE[ignoreDir]}/global.ignore"
ignoreme
EOF

cat <<EOF > "${ARKLONE[ignoreDir]}/test.ignore"
ignoremetoo
EOF

# Dir is in ignore list
isIgnored "/path/to/ignoreme" "${ARKLONE[ignoreDir]}/global.ignore"

[ $? = 0 ] || exit 70

# Dir is not in ignore list
isIgnored "/path/to/foo" "${ARKLONE[ignoreDir]}/global.ignore"

[ $? != 0 ] || exit 70

# Mock directory tree
SAVES_DIR="/dev/shm/saves"

mkdir "${SAVES_DIR}"
mkdir "${SAVES_DIR}/ignoreme"
mkdir "${SAVES_DIR}/nes"
mkdir "${SAVES_DIR}/nes/FCEUmm"
mkdir "${SAVES_DIR}/nes/ignoremetoo"
mkdir "${SAVES_DIR}/snes"
mkdir "${SAVES_DIR}/snes/bsnes"

# Make depth 0 path units
newPathUnitsFromDir "${SAVES_DIR}" "remotedir" 1 true "filter" "${ARKLONE[ignoreDir]}/test.ignore"

# Units exist
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes.sub.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes.sub.auto.path" ] || exit 72

# Ignored units do not exit
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-ignoreme.sub.auto.path" ] || exit 70

# Depth 1 units do not exit
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-fceumm.sub.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-ignoremetoo.sub.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-bsnes.sub.auto.path" ] || exit 70

# Reset units dir
rm "${ARKLONE[unitsDir]}/"*".path"

# Make depth 1 path units, no root unit
newPathUnitsFromDir "${SAVES_DIR}" "remotedir" 2 false "filter" "${ARKLONE[ignoreDir]}/test.ignore"

# Units exit
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-FCEUmm.sub.auto.path" ] || exit 72
[ -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes-bsnes.sub.auto.path" ] || exit 72

# Ignored units do not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-ignoremetoo.sub.auto.path" ] || exit 70

# Root unit does not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir.auto.path" ] || exit 70

# Depth 0 units do not exist
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-nes.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-snes.auto.path" ] || exit 70
[ ! -f "${ARKLONE[unitsDir]}/arkloned-remotedir-ignoreme.auto.path" ] || exit 70

# Instance name is correct
INSTANCE_NAME="$(grep "Unit=" "${ARKLONE[unitsDir]}/arkloned-remotedir-nes-FCEUmm.sub.auto.path" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')"
INSTANCE_NAME="$(systemd-escape -u -- "${INSTANCE_NAME}")"

[ "${INSTANCE_NAME}" = "${SAVES_DIR}/nes/FCEUmm@remotedir/nes/FCEUmm@filter" ] || exit 78

# Teardown
rm -rf "${ARKLONE[unitsDir]}"
rm -rf "${ARKLONE[ignoreDir]}"
rm -rf "${SAVES_DIR}"
