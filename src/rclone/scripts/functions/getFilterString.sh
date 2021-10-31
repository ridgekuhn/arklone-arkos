#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

# Build a filter string to pass to rclone
#
# Returns global filter by default, and appends filter list if passed.
#
# @usage
#		filterString="$(getFilterString "filter1|filter2|filter3|etc")"
#
# @see https://rclone.org/filtering/
#
# @param [$1] Optional pipe-delimited list of filters
#
# @returns Concatenated filter string
function getFilterString() {
    # Split pipe | delimited list of filters into array
    local filters=($(tr '|' '\n' <<<"${1}"))

    # Prepare strings
    local filesString=""
    local excludeString=" --exclude-from=${ARKLONE[filterDir]}/global.exclude"
    local filterString=""
    local includeString=""

    # Populate strings
    for filter in ${filters[@]}; do
        if [[ -f "${ARKLONE[filterDir]}/${filter}.files" ]]; then
            filesString+=" --files-from=${ARKLONE[filterDir]}/${filter}.files"
        fi

        if [[ -f "${ARKLONE[filterDir]}/${filter}.exclude" ]]; then
            excludeString+=" --exclude-from=${ARKLONE[filterDir]}/${filter}.exclude"
        fi

        if [[ -f "${ARKLONE[filterDir]}/${filter}.filter" ]]; then
            filterString+=" --filter-from=${ARKLONE[filterDir]}/${filter}.filter"
        fi

        if [[ -f "${ARKLONE[filterDir]}/${filter}.include" ]]; then
            includeString+=" --include-from=${ARKLONE[filterDir]}/${filter}.include"
        fi
    done

    # Concatenate strings
    local fullString="${filesString}${excludeString}${filterString}${includeString}"

    # Strip opening whitespace
    echo "${fullString# }"
}

