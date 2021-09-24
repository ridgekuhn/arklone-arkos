#!/bin/bash
# Print array items formatted for whiptail menu
#
# @param $1 {string} list of menu options
#
# @returns {string} space-delimited array of menu indexes and options
function printMenu() {
	local items=($1)

	for (( i = 0; i < ${#items[@]}; i++ )); do
		printf "$i ${items[i]} "
	done
}

