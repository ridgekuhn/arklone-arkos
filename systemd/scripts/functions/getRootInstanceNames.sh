#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"

# Get instance names of all systemd path modules not ending in .sub.auto.path
#
# @returns {string} space-delimted list of unescaped instance names
function getRootInstanceNames() {
    # Get all units not ending in sub.auto.path
    local units=($(find "${ARKLONE[unitsDir]}/arkloned-"*".path" | grep -v "sub.auto.path"))

    # Get instance name and unescape it
    for unit in ${units[@]}; do
        local escapedName=$(grep "Unit=" ${unit} | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')
        local instanceName=$(systemd-escape -u -- "${escapedName}")

        printf "${instanceName} "
    done
}

