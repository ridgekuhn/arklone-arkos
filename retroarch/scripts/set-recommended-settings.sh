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
# @param $1 {string} Path to retroarch.cfg
#
# @param [$2] {string} Optional path to saves dir,
#		Defaults to "$(dirname ${1})/saves"

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t loadConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/loadConfig.sh"
[ "$(type -t editConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/editConfig.sh"
[ "$(type -t isIgnored)" = "function" ] || source "${ARKLONE[installDir]}/functions/isIgnored.sh"

# Get the path to retroarch.cfg
RETROARCH_CFG="${1}"
SAVES_DIR=$([ ${2} ] && echo "${2}" || echo "$(dirname "${RETROARCH_CFG}")/saves")

echo "========================================================================="
echo "Now editing ${RETROARCH_CFG}"
echo "-------------------------------------------------------------------------"

# Make the save directory if it doesn't exist
if [ ! -d "${SAVES_DIR}" ]; then
	mkdir "${SAVES_DIR}"
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
		[ ! -z "$(ls -A "${contentDir}")" ] \
		&& ! isIgnored "${contentDir}" "${ARKLONE[ignoreDir]}/global.ignore" \
		&& ! isIgnored "${contentDir}" "${ARKLONE[ignoreDir]}/arkos-retroarch-content-root.ignore"
	then
		# Make a corresponding directory in ${SAVES_DIR}
		saveDir="${SAVES_DIR}/$(basename "${contentDir}")"

		if [ ! -d "${saveDir}" ]; then
		 	mkdir "${saveDir}"
		fi
	fi
done

# Reset IFS
IFS=$oIFS

# Backup retroarch.cfg
cp -v "${RETROARCH_CFG}" "${RETROARCH_CFG}.arklone$(date +%s).bak"

# Modify savefile settings
echo "Setting savefile_directory to ${SAVES_DIR}"
editConfig "savefile_directory" "${SAVES_DIR}" "${RETROARCH_CFG}"

echo "Setting savefiles_in_content_dir to false"
editConfig "savefiles_in_content_dir" "false" "${RETROARCH_CFG}"

echo "Setting sort_savefiles_by_content_enable to true"
editConfig "sort_savefiles_by_content_enable" "true" "${RETROARCH_CFG}"

echo "Setting sort_savefiles_enable to false"
editConfig "sort_savefiles_enable" "false" "${RETROARCH_CFG}"

# Modify savestate settings
echo "Setting savestate_directory to ${SAVES_DIR}"
editConfig "savestate_directory" "${SAVES_DIR}" "${RETROARCH_CFG}"

echo "Setting savestates_in_content_dir to false"
editConfig "savestates_in_content_dir" "false" "${RETROARCH_CFG}"

echo "Setting sort_savestates_by_content_enable to true"
editConfig "sort_savestates_by_content_enable" "true" "${RETROARCH_CFG}"

echo "Setting sort_savestates_enable to false"
editConfig "sort_savestates_enable" "false" "${RETROARCH_CFG}"

