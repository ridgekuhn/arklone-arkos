#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Mock retroarch.cfg to test ArkOS exFAT bug
# @todo How can we test this on non-ArkOS without creating an exFAT partition?
#ARKLONE[retroarchCfg]="/dev/shm/retroarch.cfg"
#
#cat <<EOF > "${ARKLONE[retroarchCfg]}"
#savefiles_in_content_dir = "true"
#savestates_in_content_dir = "true"
#EOF

# Mock called functions
function deletePathUnits() {
	local units=(${@})

	for unit in ${units[@]}; do
		# Check function was called with retroarch path units only
		if ! grep -E "arkloned-retroarch.*\.auto\.path$" <<<"${unit}"; then
			echo "deletePathUnits called with non-retroarch path"
			exit 64
		fi
	done
}

# Mock retroarch.cfg
mkdir "/dev/shm/retroarch32"
ARKLONE[retroarchCfg]="/dev/shm/retroarch32/retroarch.cfg"

########
# TEST 1
########
# Only generate root directory units
cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "false"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "false"
savestate_directory = "/foo/bar"
savestates_in_content_dir = "false"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "false"
EOF

# Mock functions
function newPathUnit() {
	[ "${1}" = "retroarch32-bar.auto" ] || exit 70
	[ "${2}" = "/foo/bar" ] || exit 70
	[ "${3}" = "retroarch32/bar" ] || exit 70
	[ "${4}" = "retroarch-savefile" ] || [ "${4}" = "retroarch-savestate" ] || exit 70
}

function newPathUnitsFromDir() {
	# Function should not have been called
	exit 70
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

[ $? = 0 ] || exit $?

echo "TEST 1 passed."

########
# TEST 2
########
# newPathUnitsFromDir() was called with correct values for depth 1
cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "false"
sort_savefiles_by_content_enable = "true"
sort_savefiles_enable = "false"
savestate_directory = "/foo/bar"
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

[ $? = 0 ] || exit $?

echo "TEST 2 passed."

########
# TEST 3
########
cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "false"
sort_savefiles_by_content_enable = "true"
sort_savefiles_enable = "true"
savestate_directory = "/foo/bar"
savestates_in_content_dir = "false"
sort_savestates_by_content_enable = "true"
sort_savestates_enable = "true"
EOF

function newPathUnitsFromDir() {
	# Function was called with correct local directory
	[ "${1}" = "/foo/bar" ] || exit 64

	# Function was called with correct remote directory
	[ "${2}" = "retroarch32/bar" ] || exit 64

	# Function was called with correct subdir depth
	[ "${3}" = "2" ] || exit 64

	# Function was called with makeRootUnit = true
	[ "${4}" = "true" ] || exit 64

	# Function was called with correct filters
	[ "${5}" = "retroarch-savefile" ] || [ "${5}" = "retroarch-savestate" ] || exit 64

	# Function was not called with ignore file
	[ -z "${6}" ] || exit 64
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"

[ $? = 0 ] || exit $?

echo "TEST 3 passed."

########
# TEST 4
########
# Skip test if run on ArkOS
if [ "$(lsblk -f | grep "EASYROMS" | cut -d ' ' -f 2)" = "exfat" ]; then
  echo "TEST 4 skipped."

# Run script
else
	ARKLONE[retroarchContentRoot]="/foo/baz"

	cat <<EOF >"${ARKLONE[retroarchCfg]}"
savefile_directory = "/foo/bar"
savefiles_in_content_dir = "true"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "false"
savestate_directory = "/foo/bar"
savestates_in_content_dir = "true"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "false"
EOF

	function newPathUnitsFromDir() {
		# Function was called with correct local directory
		[ "${1}" = "/foo/baz" ] || exit 64

		# Function was called with correct remote directory
		[ "${2}" = "retroarch32/baz" ] || exit 64

		# Function was called with correct subdir depth
		[ "${3}" = "1" ] || exit 64

		# Function was called with makeRootUnit = true
		[ "${4}" = "true" ] || exit 64

		# Function was called with correct filters
		[ "${5}" = "retroarch-savefile|retroarch-savestate" ] || exit 64

		# Function was called with correct ignore file
		# @todo ArkOS-specific
		[ "${6}" = "${ARKLONE[ignoreDir]}/arkos-retroarch-content-root.ignore" ] || exit 64
	}

		echo "TEST 4 passed."
fi

########
# TEST 5
########
# deletePathUnits was called
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"
touch "${ARKLONE[unitsDir]}/arkloned-retroarch-foo.auto.path"

# Mock functions
function deletePathUnits() {
	[ "${1}" = "${ARKLONE[unitsDir]}/arkloned-retroarch-foo.auto.path" ] || exit 64
}

function newPathUnitsFromDir() {
	return
}

# Run script
. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh" true

echo "TEST 5 passed."

##########
# TEARDOWN
##########
rm "${ARKLONE[retroarchCfg]}"
rm -rf "${ARKLONE[unitsDir]}"

