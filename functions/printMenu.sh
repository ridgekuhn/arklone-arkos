#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Print space-delimited list formatted for whiptail menu
#
# @param $1 {string} list of menu options
#
# @returns {string} space-delimited list of menu indexes and options
function printMenu() {
	local items=($1)

	for (( i = 0; i < ${#items[@]}; i++ )); do
		printf "$i ${items[i]} "
	done
}

