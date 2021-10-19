#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"
[[ "$(type -t isIgnored)" = "function" ]] || source "${ARKLONE[installDir]}/functions/isIgnored.sh"
[[ "$(type -t newPathUnit)" = "function" ]] || source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"

# Make path unit for directory, and optionally for subdirectories
#
# @param $1 {string} Absolute path to the local parent directory
#
# @param $2 {string} Remote parent directory path.
#		No opening or trailing slashes.
#
# @param $3 {number} Depth of subdirectories to recurse
#
# @param [$4] {boolean} Create a path unit for the parent directory.
#		Defaults to true
#
# @param [$5] {string} Optional pipe | delimited list of rclone filter names in
#		${ARKLONE[installDir]}/rclone/filters
#		Pass file name only, no extension or leading directory path.
#		Filter will be shared by all subdirectory path units.
#
# @param [$6] {string} Optional absolute path
#		to a list of directory names to ignore
function newPathUnitsFromDir() {
    local localParentDir="${1}"
    local remoteParentDir="${2}"

    # Get subdirectories of depth $3
    local subdirDepth=$3
    local subdirs=($(find "${localParentDir}" -mindepth $subdirDepth -maxdepth $subdirDepth -type d 2>/dev/null))
    local createParentUnit=$([[ -z $4 ]] && echo true || echo "${4}")
    local filter="${5}"
    local ignoreList="${6}"

    local globalIgnoreList="${ARKLONE[ignoreDir]}/global.ignore"

    # Save default $IFS
    local oIFS="${IFS}"

    #####
    # RUN
    #####
    # Make root unit
    if [[ "${createParentUnit}" = "true" ]]; then
        # Convert forward slashes / in ${remoteParentDir} to hyphens -
        # eg,
        # remoteParentDir="retroarch32/savestates"
        # localParentDir="/path/to/savestates"
        # filter="retroarch-savestate"
        # newPathUnit "retroarch32-savestates.auto" "/path/to/savestates" "retroarch32/savestates" "retroarch-savestate"
        newPathUnit "${remoteParentDir//\//-}.auto" "${localParentDir}" "${remoteParentDir}" "${filter}"
    fi

    for subdir in ${subdirs[@]}; do
        # Escape tab and space
        IFS=$'\n'

        # Build unit name

        # Use basename to strip leading path from ${subdir}
        #	Convert spaces in poorly-named ${subdir} to underscores _
        # eg,
        # subDir="/path/to/poorly named dir"
        # subdirString="poorly_named_dir"
        local subdirString="$(basename "${subdir//\ /_}")"

        # Prepend depth 1 dir if depth 2
        # eg,
        # subDir="/path/to/savestates/foo/bar"
        # subdirString="foo/bar"
        if [[ "${subdirDepth}" = 2 ]]; then
            subdirString="$(basename $(dirname "${subdir}"))/${subdirString}"
        fi

        # Convert forward slashes / to hyphens -
        # eg,
        # subdirBasename="foo/bar"
        # remoteParentDir="retroarch32/savestates"
        #	unitName="retroarch32-savestates-foo-bar.sub.auto"
        local unitName="${remoteParentDir//\//-}-${subdirString//\//-}.sub.auto"

        # Reset IFS
        IFS="${oIFS}"

        # Check ignore lists and continue to next subdir if in ignore list
        if \
            isIgnored "${subdir}" "${globalIgnoreList}" \
            || isIgnored "${subdir}" "${ignoreList}"
        then
            continue
        fi

        # Make a new path unit
        # eg,
        # unitName="retroarch32"
        # subdir="/path/to/savestates/nes"
        # remoteParentDir="retroarch32"
        # filter="retroarch-savestate"
        #
        # newPathUnit "retroarch32" "/path/to/savestates/nes" "retroarch32/nes" "retroarch-savestate"
        newPathUnit "${unitName}" "${subdir}" "${remoteParentDir}/${subdirString}" "${filter}"
    done
}

