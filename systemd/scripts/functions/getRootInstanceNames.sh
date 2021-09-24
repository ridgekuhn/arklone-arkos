#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Get instance names of all systemd path modules not ending in .sub.auto.path
#
# @returns {string} space-delimted list of unescaped instance names
function getRootInstanceNames() {
	# @todo replace xargs with regex in find argument
	local units=($(find "${ARKLONE[unitsDir]}/"*".path" -print0 | xargs -0 -I {} bash -c 'unit={}; if [ ! -z "${unit##*sub.auto.path}" ]; then echo "${unit}"; fi'))

	for (( i = 0; i < ${#units[@]}; i++ )); do
		local escapedName=$(awk -F '@' '/Unit/ {split($2, arr, ".service"); print arr[1]}' "${units[i]}")
		local instanceName=$(systemd-escape -u -- "${escapedName}")

		printf "${instanceName} "
	done
}
