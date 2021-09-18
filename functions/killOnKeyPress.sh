#!/bin/bash
# Run a script and kill it on user keypress
#
# @param $1 {number} The script to run
#
# @returns Exit/return code of script $1
function killOnKeypress() {
	local script=${1}

	# Run the script in the background
	$script &

	# Get the process id of $script
	local pid=$!

	# Monitor $script and listen for keypress in foreground
	while kill -0 "${pid}" >/dev/null 2>&1; do
		# If key pressed, kill $script and return with code 1
		read -sr -n 1 -t 1 && kill "${pid}" && return 1
	done

	# Set $? to return code of $script
	wait $pid

	# Return $script's exit code
	return $?
}
