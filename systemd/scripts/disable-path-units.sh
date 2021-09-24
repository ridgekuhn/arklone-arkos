#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

# Store list of enabled unit names in an array
AUTOSYNC=(${ARKLONE[autoSync]})

# Disable path units
if [ "${#AUTOSYNC[@]}" -gt 0 ]; then
	for unit in ${AUTOSYNC[@]}; do
		sudo systemctl disable "${unit}"
	done

	# Unlink path unit service template
	sudo systemctl disable "arkloned@.service"
fi
