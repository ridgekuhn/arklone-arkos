#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Run a command and kill it on user keypress
#
# @param $1 {number} The command to run
#
# @param [$2] {*} Optional arguments to pass to command
#
# @returns Exit/return code of script $1
function killOnKeypress() {
	local runcommand="${1}"
	local args=(${@:2})

	# Run the command in the background
	"${runcommand}" ${args[@]} &

	# Get the process id of $runcommand
	local pid=$!

	# Monitor $runcommand and listen for keypress in foreground
	while kill -0 "${pid}" >/dev/null 2>&1; do
		# If key pressed, kill $runcommand and return with code 1
		read -sr -n 1 -t 1 && kill "${pid}" && return 1
	done

	# Set $? to return code of $runcommand
	wait $pid

	# Return $runcommand's exit code
	return $?
}

