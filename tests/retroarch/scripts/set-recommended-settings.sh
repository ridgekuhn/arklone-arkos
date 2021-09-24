#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/loadConfig.sh"

RETROARCH_CFG="/dev/shm/retroarch.cfg"

# Mock retroarch.cfg
cat <<EOF >"${RETROARCH_CFG}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "true"
sort_savefiles_by_content_enable = "true"
sort_savefiles_enable = "true"
savestates_directory = "/foo/bar"
savestates_in_content_dir = "true"
sort_savestates_by_content_enable = "true"
sort_savestates_enable = "true"
EOF

. "${ARKLONE[installDir]}/retroarch/scripts/set-recommended-settings.sh" "${RETROARCH_CFG}"

# Get modified settings
declare -A r
loadConfig "${RETROARCH_CFG}" r

# retroarch.cfg.aklone(date).bak exists
if ! find "/dev/shm/retroarch.cfg.arklone"*".bak"; then
	exit 72
fi

# Savefile settings modified and directory exists
[ "${r[savefile_directory]}" = "/dev/shm/saves" ]
[ -d "/dev/shm/saves" ] || exit 72

# Savefile settings were modified
[ "${r[savefiles_in_content_dir]}" = "false" ] || exit 78
[ "${r[sort_savefiles_by_content_enable]}" = "false" ] || exit 78
[ "${r[sort_savefiles_enable]}" = "false" ] || exit 78

# Savestate settings modified and directory exists
[ "${r[savestate_directory]}" = "/dev/shm/states" ]
[ -d "/dev/shm/states" ] || exit 72

# Savefile settings were modified
[ "${r[savestates_in_content_dir]}" = "false" ] || exit 78
[ "${r[sort_savestates_by_content_enable]}" = "false" ] || exit 78
[ "${r[sort_savestates_enable]}" = "false" ] || exit 78

# Teardown
rm "${RETROARCH_CFG}"
rm "/dev/shm/retroarch.cfg.arklone"*".bak"
rm -rf "/dev/shm/saves"
rm -rf "/dev/shm/states"
