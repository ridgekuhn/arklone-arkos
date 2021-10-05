#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Enable systemd path units for watching directories
#
# Since systemd is incapable of watching subdirectories,
# only enables units ending in .path, and .sub.auto.path, but not .auto.path

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t isIgnored)" = "function" ] || source "${ARKLONE[installDir]}/functions/isIgnored.sh"

# Store list of enabled unit names in an array
ENABLED_UNITS=(${ARKLONE[enabledUnits]})

# Generate and enable path units
if [ "${#ENABLED_UNITS[@]}" = 0 ]; then
	# Get all services
	SERVICES=($(find "${ARKLONE[unitsDir]}/"*".service"))
	# Get all path units
	UNITS=($(find "${ARKLONE[unitsDir]}/"*".path"))

	# If path units ending in *.sub.auto.path are found,
	# we should not enable the ${ARKLONE[retroarchContentRoot]} unit,
	# or the units for paths specified for
	# "savefile_directory" and "savestate_directory" in retroarch.cfg
	# @todo Remove this in the future so we can watch root unit paths
	#		to generate new path units when new subdirectories are created
	NO_ROOT_UNITS=$(find "${ARKLONE[unitsDir]}/"*".sub.auto.path" >/dev/null 2>&1)

	# Enable services, but do not start
	# to protect the cloud copy from a bad sync
	for service in ${SERVICES[@]}; do
		# Skip ignored units
		if isIgnored "${service}" "${ARKLONE[ignoreDir]}/autosync.ignore"; then
			continue
		fi

		sudo systemctl enable "${service}"
	done

	# Enable path units, but do not start
	# to protect the cloud copy from a bad sync
	for unit in ${UNITS[@]}; do
		# Skip ignored units
		if isIgnored "${unit}" "${ARKLONE[ignoreDir]}/autosync.ignore"; then
			continue
		fi

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
fi

