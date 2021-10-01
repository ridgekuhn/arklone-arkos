#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/loadConfig.sh"

RETROARCH_CFG="/dev/shm/retroarch.cfg"

# Mock retroarch.cfg
cat <<EOF >"${RETROARCH_CFG}"
savefile_directory = "/dev/bar"
savefiles_in_content_dir = "true"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "true"
savestates_directory = "/foo/bar"
savestates_in_content_dir = "true"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "true"
EOF

# Mock ${ARKLONE[retroarchContentRoot]}
ARKLONE[retroarchContentRoot]="/dev/shm/roms"
mkdir "${ARKLONE[retroarchContentRoot]}"
mkdir "${ARKLONE[retroarchContentRoot]}/nes"
touch "${ARKLONE[retroarchContentRoot]}/nes/test"
mkdir "${ARKLONE[retroarchContentRoot]}/snes"
touch "${ARKLONE[retroarchContentRoot]}/snes/test"
mkdir "${ARKLONE[retroarchContentRoot]}/ports"
mkdir "${ARKLONE[retroarchContentRoot]}/.Trashes"

# Run script
. "${ARKLONE[installDir]}/retroarch/scripts/set-recommended-settings.sh" "${RETROARCH_CFG}"

# retroarch.cfg.aklone(date).bak exists
if ! find "/dev/shm/retroarch.cfg.arklone"*".bak"; then
	exit 72
fi

# Get modified settings
declare -A r
loadConfig "${RETROARCH_CFG}" r

# Savefile settings modified and directory exists
[ "${r[savefile_directory]}" = "/dev/shm/saves" ] || exit 72
[ -d "${r[savefile_directory]}" ] || exit 72

# Savefile settings were modified
[ "${r[savefiles_in_content_dir]}" = "false" ] || exit 78
[ "${r[sort_savefiles_by_content_enable]}" = "true" ] || exit 78
[ "${r[sort_savefiles_enable]}" = "false" ] || exit 78

# Savestate settings modified and directory exists
[ "${r[savestate_directory]}" = "/dev/shm/saves" ]
[ -d "${r[savefile_directory]}" ] || exit 72

# Savefile settings were modified
[ "${r[savestates_in_content_dir]}" = "false" ] || exit 78
[ "${r[sort_savestates_by_content_enable]}" = "true" ] || exit 78
[ "${r[sort_savestates_enable]}" = "false" ] || exit 78

# RetroArch content dir hierarchy was created
[ -d "${r[savefile_directory]}/nes" ] || exit 72
[ -d "${r[savefile_directory]}/snes" ] || exit 72
[ ! -d "${r[savefile_directory]}/ports" ] || exit 70
[ ! -d "${r[savefile_directory]}/.Trashes" ] || exit 70

# Teardown
rm "${RETROARCH_CFG}"
rm "/dev/shm/retroarch.cfg.arklone"*".bak"
rm -rf "/dev/shm/saves"
rm -rf "/dev/shm/states"
rm -rf "/dev/shm/roms"
