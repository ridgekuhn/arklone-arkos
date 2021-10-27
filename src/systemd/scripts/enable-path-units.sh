#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Enable systemd path units for watching directories
#
# Since systemd is incapable of watching subdirectories,
# only enables units ending in .path, and .sub.auto.path, but not .auto.path
#
# To output progress percentage for passing to dialog gauge,
# @see dialogs/gauges/systemd/enable-path-units.sh

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t isIgnored)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/isIgnored.sh"

# Get all services
SERVICES=($(find "${ARKLONE[unitsDir]}/"*".service"))
# Get all path units
PATH_UNITS=($(find "${ARKLONE[unitsDir]}/"*".path"))
#Get all timers
TIMERS=($(find "${ARKLONE[unitsDir]}/"*".timer"))

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

    # Only link service templates
    # and service units with corresponding timers,
    # do not enable them.
    if \
        grep "@.service" <<<"${service}" \
        || [[ -f "$(sed -e 's/.service$/.timer/' <<<"${service}")" ]]
    then
        sudo systemctl link "${service}"

        continue
    fi

    sudo systemctl enable "${service}"
done

# Enable path units, but do not start
# to protect the cloud copy from a bad sync
for unit in ${PATH_UNITS[@]}; do
    # Skip ignored units
    if isIgnored "${unit}" "${ARKLONE[ignoreDir]}/autosync.ignore"; then
        continue
    fi

    # Skip root path units
    # @todo see above todo
    if
        [[ $NO_ROOT_UNITS ]] \
        && [[ "${unit:(-10)}" = ".auto.path" ]] \
        && [[ "${unit:(-14)}" != ".sub.auto.path" ]]
    then
        continue
    fi

    sudo systemctl enable "${unit}"
done

# Enable timer units, but do not start
# to protect the cloud copy from a bad sync
for timer in ${TIMERS[@]}; do
    # Skip ignored units
    if isIgnored "${unit}" "${ARKLONE[ignoreDir]}/autosync.ignore"; then
        continue
    fi

    sudo systemctl enable "${timer}"
done

