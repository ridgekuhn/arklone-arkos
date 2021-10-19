#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Build a filter string to pass to rclone
#
# Returns global filter by default, and appends filter list if passed.
#
# @usage
#		filterString="$(getFilterString "filter1|filter2|filter3|etc")"
#
# @param [$1] Optional pipe-delimited list of filters
#
# @returns Concatenated filter string
function getFilterString() {
    # Split pipe | delimited list of filters into array
    local filters=($(tr '|' '\n' <<<"${1}"))

    # Array of supported retroarch filters
    local retroarchFilters=("retroarch-savefile" "retroarch-savestate")

    # Check ${filters[@]} for retroarch filters
    local duplicates=($(tr ' ' '\n' <<<"${filters[@]} ${retroarchFilters[@]}" | sort | uniq -d))

    if [ ${#duplicates[@]} -gt 0 ]; then
        # Remove retroarch filters
        local unique=$(tr ' ' '\n' <<<"${filters[@]} ${retroarchFilters[@]}" | grep -v "retroarch")

        # Replace retroarch filters with global retroarch filter
        filters=("retroarch" ${unique})
    fi

    # Start building filter-from string
    local filterString="--filter-from ${ARKLONE[filterDir]}/global.filter"

    # Append passed filters
    for filter in ${filters[@]}; do
        filterString+=" --filter-from ${ARKLONE[filterDir]}/${filter}.filter"
    done

    echo "${filterString}"
}


