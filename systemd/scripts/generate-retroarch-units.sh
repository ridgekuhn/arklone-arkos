#!/bin/bash
# arklone retroarch path unit generator
# by ridgek

source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/loadConfig.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/deletePathUnits.sh"
source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnitsFromDir.sh"

# Get array of all retroarch.cfg instances
RETROARCHS=(${ARKLONE[retroarchCfg]})

# Get list of subdirs to ignore
IGNORE_DIRS="${ARKLONE[installDir]}/systemd/scripts/includes/arkos-retroarch-content-root.ignore"

# @todo We should also be able to support screenshots and systemfiles
#		because they use the same naming scheme in retroarch.cfg
FILETYPES=("savefile" "savestate")

Remove old units
# @todo pass an arg to script to run
deletePathUnits "$(find "${ARKLONE[installDir]}/systemd/units/arkloned-retroarch"*".auto.path" 2>/dev/null)"

# Loop through retroarch instances
for retroarchCfg in ${RETROARCHS[@]}; do
	# Get the retroarch instance's config directory
	# @todo see if I even use this
	retroarchCfgDir="$(dirname "${retroarchCfg}")"

	# Get the retroarch instance's basename
	# eg, retroarch or retroarch32
	retroarchBasename="$(basename "${retroarchCfgDir}")"

	# Create an array to hold retroarch.cfg settings plus a few of our own
	declare -A r

	# Load relevant settings into r
	# Last param passed to loadConfig()
	# is ${FILETYPES[@]} as a pipe | delimited list.
	# The pipes will become regex OR operators passed to grep
	# @see functions/loadConfig.sh
	loadConfig "${retroarchCfg}" r "$(tr ' ' '|' <<<"${FILETYPES[@]}")"

	for filetype in ${FILETYPES[@]}; do
		# If ${filetype}s_in_content_dir is enabled, it supercedes the other relevant settings
		# and ${filetype} will always appear next to the corresponding content file
		#
		# @todo I hate this syntax, is there anything that can be done about it?
		# Check if = "true" because it's a string, not an actual boolean
		if [ "${r[${filetype}s_in_content_dir]}" = "true" ]; then
			# Save/append the content dir parent filter string
			# so we can do newPathUnitsFromDir()
			# in one shot without waiting to check for duplicate units
			r[content_directory_filter]+="${filetype}|"

			# Continue to next filetype, we will generate the content dir units last
			continue

		# These settings combined means files are organized
		# by subdirectories named after the corresponding content dir,
		# then by another level named after the retroarch core
		# that generated the file
		# eg,
		# "${r[${filetype}_directory]}/nes/FCEUmm"
		elif
			[ "${r[sort_${filetype}s_by_content_enable]}" = "true" ] \
			&& [ "${r[sort_${filetype}s_enable]}" = "true" ]
		then
			# This will be passed to find's -mindepth -maxdepth options,
			# where depth 0 recurses the working directory (and lists subdirs),
			# and depth 1 recurses subdirectories and lists sub-subdirs
			r[${filetype}_directory_depth]=1

		else
			r[${filetype}_directory_depth]=0
		fi

		# Process the ${filetype} directory
		newPathUnitsFromDir "${r[${filetype}_directory]}" "${retroarchBasename}/$(basename "${r[${filetype}_directory]}")" "${r[${filetype}_directory_depth]}" true "retroarch-${filetype}"
	done

	# Process the retroarch content root
	# @todo ArkOS-specific
	if [ ${r[content_directory_filter]} ]; then
		newPathUnitsFromDir "${ARKLONE[retroarchContentRoot]}" "${retroarchBasename}" 0 true "${r[content_directory_filter]}" "arkos-retroarch-content-root.ignore"
	fi
done
