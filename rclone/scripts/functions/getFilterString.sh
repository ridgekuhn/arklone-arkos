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

	local filterString="--filter-from ${ARKLONE[filterDir]}/global.filter"

	for filter in ${filters[@]}; do
		filterString+=" --filter-from ${ARKLONE[filterDir]}/${filter}.filter"
	done

	echo "${filterString}"
}

