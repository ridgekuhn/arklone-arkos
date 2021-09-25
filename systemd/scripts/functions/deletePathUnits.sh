#!/bin/bash
# Delete path units
#
# Accepts multiple path unit paths as arguments
#
#	@param $@ {string} Path(s) to units to delete
function deletePathUnits() {
	# Store all passed args as an array
	local oldUnits=($@)

	echo "Cleaning up old path units..."

	for oldUnit in ${oldUnits[@]}; do
		# Check if path unit is linked to systemd
		linked=$(systemctl list-unit-files | grep "${oldUnit##*/}")

		printf "\nRemoving old unit: ${oldUnit##*/}...\n"

		# Disable the linked unit
		if [ "${linked}" ]; then
			sudo systemctl disable "${oldUnit##*/}"
		fi

		# Delete the old unit
		sudo rm -v "${oldUnit}"
	done
}
