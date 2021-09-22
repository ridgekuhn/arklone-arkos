#!/bin/bash
# @returns exit code 65 for ArkOS exFAT bug
source "/opt/arklone/config.sh"

# @todo ArkOS exFAT bug
#		A bug in ArkOS prevents systemd path units
#		from being able to reliably watch an exFAT partition.
#		This means automatic syncing will not work if
#		"savefiles_in_content_dir" or "savestates_in_content_dir"
#		are enabled.
#
#		User will still be able to manually sync.
#
#		@see https://github.com/christianhaitian/arkos/issues/289

# Check if an exFAT partition named EASYROMS is present
if [ "$(lsblk -f | grep "EASYROMS" | cut -d ' ' -f 2)" = "exfat" ]; then
	# Get array of retroarch.cfg instances
	RETROARCH_CFGS=(${ARKLONE[retroarchCfg]})

	# Loop through all retroarch.cfg instances
	for retroarchCfg in ${RETROARCH_CFGS[@]}; do
		# Store retroarch.cfg settings in an array
		declare -A r
		loadConfig "${retroarchCfg}" r "savefiles_in_content_dir|savestates_in_content_dir"

		# Check for incompatible settings
		if
			[ "${r[savefiles_in_content_dir]}" = "true" ] \
			|| [ "${r[savestates_in_content_dir]}" = "true" ]
		then
			exit 65
		fi
	done
fi

# Store list of enabled unit names in an array
AUTOSYNC=(${ARKLONE[autoSync]})

# Generate and enable path units
if [ "${#AUTOSYNC[@]}" = 0 ]; then
	# Generate new RetroArch path units if none exist
	if ! find "${ARKLONE[installDir]}/systemd/units/"*"retroarch"*; then
		"${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh"
	fi

	# Get all path units
	UNITS=($(find "${ARKLONE[installDir]}/systemd/units/"*".path"))

	# If path units ending in *.sub.auto.path are found,
	# we should not enable the ${ARKLONE[retroarchContentRoot]} unit,
	# or the units for paths specified for
	# "savefile_directory" and "savestate_directory" in retroarch.cfg
	# @todo Remove this in the future so we can watch root unit paths
	#		to generate new path units when new subdirectories are created
	NO_ROOT_UNITS=$(find "${ARKLONE[installDir]}/systemd/units/"*".sub.auto.path")

	# Link path unit service template
	sudo systemctl link "${ARKLONE[installDir]}/systemd/units/arkloned@.service"

	# Enable path units, but do not start
	# to protect the cloud copy from a bad sync
	for unit in ${UNITS[@]}; do
		# Skip root path units
		# @todo see above todo
		if
			[ $NO_ROOT_UNITS ] \
			&& [ "${unit:(-10)}" = ".auto.path" ] \
			&& [ "${unit:(-14)}" != ".sub.auto.path" ]
		then
			continue
		fi

		sudo systemctl enable "${unit}"
	done

	# Enable boot sync service
	sudo systemctl enable "${ARKLONE[installDir]}/systemd/units/arkloned-saves-sync-boot.service"

# Disable units
else
	# Disable path units
	for unit in ${AUTOSYNC[@]}; do
		sudo systemctl disable "${unit}"
	done

	# Disable path unit service template
	sudo systemctl disable "arkloned@.service"

	# Disable boot sync service
	sudo systemctl disable arkloned-receive-saves-boot.service
fi
