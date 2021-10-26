#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

# Check if a path unit using a local directory and rclone filter already exists
#
#	If filter is not a duplicate, function returns with code 1
#	and outputs a pipe | delimited string to STDERR,
#	containing all the existing filters, plus the new one passed in $2
#
#	@usage
#		# If used inside a function,
#		# declare the var as local independently from assignment,
#		# or $? will be the exit code of the local assignment,
#		# instead of the subshell running unitExists()
#		local newFilterList
#		newFilterList=$((unitExists "/path/to/localDir" "some-filter") 2>&1)
#
#		if [[ $? != 0 ]] && [[ "${newFilterList}" ]]; then
#			echo "${newFilterList}"
#			# some-filter|some-other-filter|yet-another-filter
#		fi
#
# @param $1 {string} Absolute path to local directory
#
# @param $2 {string} rclone filter name
#		ie, the name of the file in ${ARKLONE[installDir]}/src/rclone/filters,
#		without the .filter extension
#
# @returns 1 if an existing unit is NOT found
#		and outputs pipe | delimited list of all filters to STDERR
function unitExists() {
    local localDir="${1}"
    local filter="${2}"
    local existingUnits=($(find "${ARKLONE[unitsDir]}/"*".path" 2>/dev/null))

    # Loop through existing units
    for existingUnit in ${existingUnits[@]}; do
        # Get the existing unit's watched directory path
        local existingDir=$(grep "PathChanged" "${existingUnit}" | cut -d '=' -f 2)

        # If ${localDir} is already being watched,
        # check if ${filter} is also being used
        if [[ "${existingDir}" = "${localDir}" ]]; then
            # Get the escaped instance name from the Unit= line
            # eg, "-home-ark.config-retroarch-saves\x40retroarch-savefiles\x40retroarch\x2dsavefile\x7cretroarch\x2dsavestate"
            local escInstanceName=$(grep "Unit" "${existingUnit}" | sed -e 's/^Unit=arkloned@//' -e 's/.service$//')

            # Get the existing unit's unescaped, pipe | delimited list of filters,
            # and store it in an array
            # eg, "retroarch-savefile|retroarch-savestate" in above example
            local existingFilters=($(systemd-escape -u -- "${escInstanceName}" | cut -d '@' -f 3- | tr '|' '\n'))

            # Create a sorted array from ${filter} and ${existingFilters}
            local allFilters=($(tr ' ' '\n' <<<"${filter} ${existingFilters[@]}" | sort))

            # If doubles are found, the unit DOES exist. Return with code 0
            if [[ "$(tr ' ' '\n' <<<"${allFilters[@]}" | uniq -d)" ]]; then
                return 0

            # If no doubles are found, unit does not exist, return error code 1
            else
                # Convert filter list to a pipe | delimited string
                local filterString=$(tr ' ' '\n' <<<"${allFilters[@]}" | uniq | tr '\n' '|')

                # Echo ${filterString} to stderr and remove any trailing pipe | characters
                echo "${filterString%%|}" >&2

                return 1
            fi
        fi
    done

    # If we made it this far, no units exist, so return error code 1
    return 1
}

