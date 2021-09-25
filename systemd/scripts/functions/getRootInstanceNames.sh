#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Get instance names of all systemd path modules not ending in .sub.auto.path
#
# @returns {string} space-delimted list of unescaped instance names
function getRootInstanceNames() {
	local units=($(find "${ARKLONE[unitsDir]}/arkloned-"*".path" | grep -v "sub.auto.path"))

	for unit in ${units[@]}; do
		local escapedName=$(grep "Unit=" ${unit} | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')
		local instanceName=$(systemd-escape -u -- "${escapedName}")

		printf "${instanceName} "
	done
}
