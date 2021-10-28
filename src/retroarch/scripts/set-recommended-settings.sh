#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

#	Set retroarch.cfg file to the following settings:
#
# savefile_directory = "~/.config/retroarch/saves"
# savefiles_in_content_dir = "false"
# sort_savefiles_enable = "false"
# sort_savefiles_by_content_enable = "true"
#
# savestate_directory = "~/.config/retroarch/saves"
# savestates_in_content_dir = "false"
# sort_savestates_enable = "false"
# sort_savestates_by_content_enable = "true"
#
# Results in savefiles and savestates stored in the same directory hierarchy
# as "${ARKLONE[retroarchContentDir]}" in saves dir
# eg,
# ~/.config/retroarch/saves/nes/TheLegendOfZelda.srm
# ~/.config/retroarch/saves/nes/TheLegendOfZelda.savestate0
#
# @param [$1] {string} Optional path to saves dir,
# 	Defaults to "$(dirname ${retroarchs[0]})/saves" as parent for savefiles and savestates
# 	for all instances of retroarch.cfg

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t loadConfig)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/loadConfig.sh"
[[ "$(type -t editConfig)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/editConfig.sh"
[[ "$(type -t isIgnored)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/isIgnored.sh"

# Get array of all retroarch.cfg instances
RETROARCHS=(${ARKLONE[retroarchCfg]})

# Get path to saves directory
SAVES_DIR=$([[ ${1} ]] && echo "${1}" || echo "$(dirname "${RETROARCHS[0]}")/saves")

for retroarchCfg in ${RETROARCHS[@]}; do
    echo "========================================================================="
    echo "Now editing ${retroarchCfg}"
    echo "-------------------------------------------------------------------------"

    # Make the save directory if it doesn't exist
    if [[ ! -d "${SAVES_DIR}" ]]; then
        mkdir "${SAVES_DIR}"
        chown "${USER}":"${USER}" "${SAVES_DIR}"
        chmod u+rw "${SAVES_DIR}"
    fi

    # Escape whitespace
    oIFS="${IFS}"
    IFS=$'\n'

    # Replicate RetroArch content dir hierarchy in ${SAVES_DIR}
    RA_CONTENT_DIRS=($(find "${ARKLONE[retroarchContentRoot]}" -mindepth 1 -maxdepth 1 -type d))

    for contentDir in ${RA_CONTENT_DIRS[@]}; do
        # If ${contentDir} is not empty, and not in global or RetroArch ignore lists
        # @todo ArkOS-specific
        if \
            [[ ! -z "$(ls -A "${contentDir}")" ]] \
            && ! isIgnored "${contentDir}" "${ARKLONE[ignoreDir]}/global.ignore" \
            && ! isIgnored "${contentDir}" "${ARKLONE[ignoreDir]}/arkos-retroarch-content-root.ignore"
        then
            # Make a corresponding directory in ${SAVES_DIR}
            saveDir="${SAVES_DIR}/$(basename "${contentDir}")"

            if [[ ! -d "${saveDir}" ]]; then
                mkdir "${saveDir}"
                chown "${USER}":"${USER}" "${saveDir}"
                chmod u+rw "${saveDir}"
            fi
        fi
    done

    # Reset IFS
    IFS=$oIFS

    # Backup retroarch.cfg
    cp -v "${retroarchCfg}" "${retroarchCfg}.arklone$(date +%s).bak"

    # Modify savefile settings
    echo "Setting savefile_directory to ${SAVES_DIR}"
    editConfig "savefile_directory" "${SAVES_DIR}" "${retroarchCfg}"

    echo "Setting savefiles_in_content_dir to false"
    editConfig "savefiles_in_content_dir" "false" "${retroarchCfg}"

    echo "Setting sort_savefiles_by_content_enable to true"
    editConfig "sort_savefiles_by_content_enable" "true" "${retroarchCfg}"

    echo "Setting sort_savefiles_enable to false"
    editConfig "sort_savefiles_enable" "false" "${retroarchCfg}"

    # Modify savestate settings
    echo "Setting savestate_directory to ${SAVES_DIR}"
    editConfig "savestate_directory" "${SAVES_DIR}" "${retroarchCfg}"

    echo "Setting savestates_in_content_dir to false"
    editConfig "savestates_in_content_dir" "false" "${retroarchCfg}"

    echo "Setting sort_savestates_by_content_enable to true"
    editConfig "sort_savestates_by_content_enable" "true" "${retroarchCfg}"

    echo "Setting sort_savestates_enable to false"
    editConfig "sort_savestates_enable" "false" "${retroarchCfg}"
done
