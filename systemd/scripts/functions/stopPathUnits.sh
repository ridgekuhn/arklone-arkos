#!/bin/bash
# Stop auto-syncing for this session
function stopPathUnits() {
	local autosync=(${ARKLONE[autoSync]})

	for pathUnit in ${autosync[@]}; do
		sudo systemctl stop "${pathUnit}"
	done
}
