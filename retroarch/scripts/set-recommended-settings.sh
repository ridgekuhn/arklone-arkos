#!/bin/bash
#	Set retroarch and retroarch32 retroarch.cfg files to the following settings:
#
# savefile_directory = "~/.config/retroarch/saves"
# savefiles_in_content_dir = "false"
# sort_savefiles_enable = "false"
# sort_savefiles_by_content_enable = "false"
#
# savestate_directory = "~/.config/retroarch/saves"
# savestates_in_content_dir = "false"
# sort_savestates_enable = "false"
# sort_savestates_by_content_enable = "false"

# @param $1 {string} Path to retroarch.cfg
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t loadConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/loadConfig.sh"
[ "$(type -t editConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/editConfig.sh"

# Get the path to retroarch.cfg
RETROARCH_CFG="${1}"
RETROARCH_DIR=$(dirname "${RETROARCH_CFG}")

# Backup retroarch.cfg
cp "${RETROARCH_CFG}" "${RETROARCH_CFG}.arklone$(date +%s).bak"

# Set savefile directory
echo "Setting savefile_directory to ${RETROARCH_DIR}/saves"

# Make the save directory if it doesn't exist
if [ ! -d "${RETROARCH_DIR}/saves" ]; then
	mkdir "${RETROARCH_DIR}/saves"
	chmod u+rw "${RETROARCH_DIR}/saves"
fi

echo "Setting savestate_directory to ${RETROARCH_DIR}/states"
editConfig "savefile_directory" "${RETROARCH_DIR}/saves" "${RETROARCH_CFG}"

echo "Setting savefiles_in_content_dir to false"
editConfig "savefiles_in_content_dir" "false" "${RETROARCH_CFG}"

echo "Setting sort_savefiles_by_content_enable to false"
editConfig "sort_savefiles_by_content_enable" "false" "${RETROARCH_CFG}"

echo "Setting sort_savefiles_enable to false"
editConfig "sort_savefiles_enable" "false" "${RETROARCH_CFG}"


if [ ! -d "${RETROARCH_DIR}/states" ]; then
	mkdir "${RETROARCH_DIR}/states"
	chmod u+rw "${RETROARCH_DIR}/states"
fi

echo "Setting savestate_directory to ${RETROARCH_DIR}/states"
editConfig "savestate_directory" "${RETROARCH_DIR}/states" "${RETROARCH_CFG}"

echo "Setting savestates_in_content_dir to false"
editConfig "savestates_in_content_dir" "false" "${RETROARCH_CFG}"

echo "Setting sort_savestates_by_content_enable to false"
editConfig "sort_savestates_by_content_enable" "false" "${RETROARCH_CFG}"

echo "Setting sort_savestates_enable to false"
editConfig "sort_savestates_enable" "false" "${RETROARCH_CFG}"
