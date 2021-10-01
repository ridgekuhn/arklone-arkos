#!/bin/bash
source "/opt/arklone/config.sh"

# Uninstall first, to reset to defaults
"${ARKLONE[installDir]}/uninstall.sh" true

# Run install test
"${ARKLONE[installDir]}/tests/install.sh"

# Get all tests
TESTS=($(find "${ARKLONE[installDir]}/tests" -type f -name "*.sh"))

# Run all tests, except this one
for test in ${TESTS[@]}; do
	# Avoid running undesirable tests
	if
		[ "${test}" != "${ARKLONE[installDir]}/tests/run-all.sh" ] \
		&& [ "${test}" != "${ARKLONE[installDir]}/tests/install.sh" ] \
		&& [ "${test}" != "${ARKLONE[installDir]}/tests/uninstall.sh" ]
	then
		echo "===================================================================="
		echo "Now running ${test}"
		echo "--------------------------------------------------------------------"

		"${test}"

		exitCode=$?

		if [ $exitCode != 0 ]; then
			"${test} failed with exit code ${exitCode}"
			"Please manually clean /dev/shm/ before continuing"
			exit
		else
			echo "SUCCESS!"
		fi
	fi
done

# Run uninstall test
"${ARKLONE[installDir]}/tests/uninstall.sh" true
