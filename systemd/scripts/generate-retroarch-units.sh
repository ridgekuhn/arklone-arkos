#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Generate systemd path units for save directories in all retroarch.cfg instances
#
# @param [$1] {boolean} Optionally delete all retroarch path units first
#
# @returns 65 for ArkOS-specific exFAT bug

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"
[[ "$(type -t loadConfig)" = "function" ]] || source "${ARKLONE[installDir]}/functions/loadConfig.sh"
[[ "$(type -t newPathUnit)" = "function" ]] || source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"
[[ "$(type -t newPathUnitsFromDir)" = "function" ]] || source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnitsFromDir.sh"

# @todo ArkOS-specific exFAT bug
#		A bug in ArkOS prevents systemd path units
#		from being able to reliably watch an exFAT partition.
#		This means automatic syncing will not work if
#		"savefiles_in_content_dir" or "savestates_in_content_dir"
#		are enabled.
#
#		User will still be able to manually sync.
#
#		@see dialogs/settings.sh
#		@see https://github.com/christianhaitian/arkos/issues/289

# Get array of all retroarch.cfg instances
RETROARCHS=(${ARKLONE[retroarchCfg]})

# Check if an exFAT partition named EASYROMS is present
if [[ "$(lsblk -f | grep "EASYROMS" | cut -d ' ' -f 2)" = "exfat" ]]; then
    # Loop through all retroarch.cfg instances
    for retroarchCfg in ${RETROARCHS[@]}; do
        # Store retroarch.cfg settings in an array
        declare -A r
        loadConfig "${retroarchCfg}" r "savefiles_in_content_dir|savestates_in_content_dir"

        # Check for incompatible settings
        if
            [[ "${r[savefiles_in_content_dir]}" = "true" ]] \
            || [[ "${r[savestates_in_content_dir]}" = "true" ]]
        then
            echo "ERROR: Incompatible settings. Cannot generate retroarch path units."
            exit 65
        fi
    done
fi

# Get list of subdirs to ignore
# @todo ArkOS specific
IGNORE_DIRS="${ARKLONE[installDir]}/systemd/scripts/includes/arkos-retroarch-content-root.ignore"

# @todo We should also be able to support screenshots and systemfiles
#		because they use the same naming scheme in retroarch.cfg
FILETYPES=("savefile" "savestate")

# Loop through retroarch instances
for retroarchCfg in ${RETROARCHS[@]}; do
    echo "====================================================================="
    echo "Now processing: ${retroarchCfg}"
    echo "---------------------------------------------------------------------"

    # Get the retroarch instance's basename
    # eg,
    # retroarchCfg="/path/to/retroarch32/retroarch.cfg"
    # retroarchBasename="retroarch32"
    retroarchBasename="$(basename "$(dirname "${retroarchCfg}")")"

    # Create an array to hold retroarch.cfg settings plus a few of our own
    declare -A r

    # Load relevant settings into r
    # Last param passed to loadConfig()
    # is ${FILETYPES[@]} as a pipe | delimited list.
    # The pipes will become regex OR operators passed to grep
    # @see functions/loadConfig.sh
    loadConfig "${retroarchCfg}" r "$(tr ' ' '|' <<<"${FILETYPES[@]}")"

    for filetype in ${FILETYPES[@]}; do
        # If ${filetype}s_in_content_dir is enabled, it supercedes the other relevant settings
        # and ${filetype} will always appear next to the corresponding content file
        #
        # @todo I hate this syntax, is there anything that can be done about it?
        # Check if = "true" because it's a string, not an actual boolean
        if [[ "${r[${filetype}s_in_content_dir]}" = "true" ]]; then
            # Save/append the content dir parent filter string
            # so we can do newPathUnitsFromDir()
            # in one shot without waiting to check for duplicate units
            r[content_directory_filter]+="retroarch-${filetype}|"

            # Continue to next filetype, we will generate the content dir units later
            continue

        # Saves are stored directly in ${r[${filetype}_directory]}
        elif
            [[ "${r[sort_${filetype}s_by_content_enable]}" = "false" ]] \
            && [[ "${r[sort_${filetype}s_enable]}" = "false" ]]
        then
            # Make the path unit
            newPathUnit "${retroarchBasename}-$(basename "${r[${filetype}_directory]}").auto" "${r[${filetype}_directory]}" "${retroarchBasename}/$(basename "${r[${filetype}_directory]}")" "retroarch-${filetype}"

            # Continue to next filetype, nothing left to do
            continue

        # Saves are organized by either content dir or retroarch core
        # eg,
        # "${r[${filetype}_directory]}/nes"
        # or
        # "${r[${filetype}_directory]}/FCEUmm"
        elif [[ "${r[sort_${filetype}s_by_content_enable]}" != "${r[sort_${filetype}s_enable]}" ]]; then
            r[${filetype}_directory_depth]=1

        # Saves are organized by content dir, then by retroarch core
        # eg,
        # "${r[${filetype}_directory]}/nes/FCEUmm"
        else
            r[${filetype}_directory_depth]=2
        fi

        newPathUnitsFromDir "${r[${filetype}_directory]}" "${retroarchBasename}/$(basename "${r[${filetype}_directory]}")" "${r[${filetype}_directory_depth]}" true "retroarch-${filetype}"
    done

    # Process the retroarch content root
    # @todo ArkOS-specific
    if [[ ${r[content_directory_filter]} ]]; then
        newPathUnitsFromDir "${ARKLONE[retroarchContentRoot]}" "${retroarchBasename}/$(basename "${ARKLONE[retroarchContentRoot]}")" 1 true "${r[content_directory_filter]%%|}" "${ARKLONE[ignoreDir]}/arkos-retroarch-content-root.ignore"
    fi

    # Unset r to prevent conflicts on next loop
    unset r
done

