#!/bin/bash
source "/opt/arklone/config.sh"

# Mock called functions
function deletePathUnits() {
	local units=(${@})

	for unit in ${units[@]}; do
		# Check function was called with retroarch path units only
		if ! grep -E "arkloned-retroarch.*.auto.path$"; then
			exit 64
		fi
	done
}

# Mock retroarch.cfg to test ArkOS exFAT bug
# @todo How can we test this on non-ArkOS without creating an exFAT partition?
#ARKLONE[retroarchCfg]="/dev/shm/retroarch.cfg"
#
#cat <<EOF > "${ARKLONE[retroarchCfg]}"
#savefiles_in_content_dir = "true"
#savestates_in_content_dir = "true"
#EOF

# Mock retroarch.cfg
ARKLONE[retroarchCfg]="/dev/shm/retroarch32/retroarch.cfg"
mkdir "/dev/shm/retroarch32"

# newPathUnitsFromDir() was called with correct values for depth 0
cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "false"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "false"
savestates_directory = "/foo/bar"
savestates_in_content_dir = "false"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "false"
EOF

function newPathUnitsFromDir() {
	# Function was called with correct local directory
	[ "${1}" = "/foo/bar" ] || exit 64

	# Function was called with correct remote directory
	[ "${2}" = "retroarch32/bar" ] || exit 64

	# Function was called with correct subdir depth
	[ "${3}" = "0" ] || exit 64

	# Function was called with makeRootUnit = true
	[ "${4}" = "true" ] || exit 64

	# Function was called with correct filters
	[ "${5}" = "retroarch-savefile" ] || [ "${5}" = "retroarch-savestate" ] || exit 64
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

# newPathUnitsFromDir() was called with correct values for depth 1
cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "false"
sort_savefiles_by_content_enable = "true"
sort_savefiles_enable = "false"
savestates_directory = "/foo/bar"
savestates_in_content_dir = "false"
sort_savestates_by_content_enable = "true"
sort_savestates_enable = "false"
EOF

function newPathUnitsFromDir() {
	# Function was called with correct local directory
	[ "${1}" = "/foo/bar" ] || exit 64

	# Function was called with correct remote directory
	[ "${2}" = "retroarch32/bar" ] || exit 64

	# Function was called with correct subdir depth
	[ "${3}" = "1" ] || exit 64

	# Function was called with makeRootUnit = true
	[ "${4}" = "true" ] || exit 64

	# Function was called with correct filters
	[ "${5}" = "retroarch-savefile" ] || [ "${5}" = "retroarch-savestate" ] || exit 64

	# Function was not called with ignore file
	[ -z "${6}" ] || exit 64
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

# newPathUnitsFromDir() was called with correct values for ${filetype}s_in_content_dir settings
ARKLONE[retroarchContentRoot]="/foo/baz"

cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "true"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "false"
savestates_directory = "/foo/bar"
savestates_in_content_dir = "true"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "false"
EOF

function newPathUnitsFromDir() {
	# Function was called with correct local directory
	[ "${1}" = "/foo/baz" ] || exit 64

	# Function was called with correct remote directory
	[ "${2}" = "retroarch32" ] || exit 64

	# Function was called with correct subdir depth
	[ "${3}" = "0" ] || exit 64

	# Function was called with makeRootUnit = true
	[ "${4}" = "true" ] || exit 64

	# Function was called with correct filters
	[ "${5}" = "retroarch-savefile|retroarch-savestate" ] || exit 64

	# Function was called with correct ignore file
	# @todo ArkOS-specific
	[ "${6}" = "arkos-retroarch-content-root.ignore" ] || exit 64
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

# Teardown
rm "${ARKLONE[retroarchCfg]}"
