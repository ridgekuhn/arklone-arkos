#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Enable systemd path units for watching directories
#
# Since systemd is incapable of watching subdirectories,
# only enables units ending in .path, and .sub.auto.path, but not .auto.path

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Store list of enabled unit names in an array
AUTOSYNC=(${ARKLONE[autoSync]})

# Generate and enable path units
if [ "${#AUTOSYNC[@]}" = 0 ]; then
	# Get all path units
	UNITS=($(find "${ARKLONE[unitsDir]}/"*".path"))

	# If path units ending in *.sub.auto.path are found,
	# we should not enable the ${ARKLONE[retroarchContentRoot]} unit,
	# or the units for paths specified for
	# "savefile_directory" and "savestate_directory" in retroarch.cfg
	# @todo Remove this in the future so we can watch root unit paths
	#		to generate new path units when new subdirectories are created
	NO_ROOT_UNITS=$(find "${ARKLONE[unitsDir]}/"*".sub.auto.path" >/dev/null 2>&1)

	# Link path unit service template
	sudo systemctl link "${ARKLONE[unitsDir]}/arkloned@.service"

	# Enable path units, but do not start
	# to protect the cloud copy from a bad sync
	for unit in ${UNITS[@]}; do
		# Skip root path units
		# @todo see above todo
		if
			[ $NO_ROOT_UNITS ] \
			&& [ "${unit:(-10)}" = ".auto.path" ] \
			&& [ "${unit:(-14)}" != ".sub.auto.path" ]
		then
			continue
		fi

		sudo systemctl enable "${unit}"
	done

	# Enable boot sync service
	sudo systemctl enable "${ARKLONE[unitsDir]}/arkloned-receive-saves-boot.service"
fi

