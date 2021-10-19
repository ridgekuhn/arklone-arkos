#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# generate-retroarch-units.sh progress gauge dialog
#
# Converts output of systemd/scripts/generate-retroarch-units.sh
# to progress percentage for passing to dialog gauge
#
#	IMPORTANT!
# @todo ArkOS-specific:
# 	Before calling this script, `pipefail` must be set,
# 	to pass non-zero exit code from main script through pipe
#
# @usage
#		set -o pipefail
#		. "${ARKLONE[installDir]}/systemd/scripts/generate-retroarch-units.sh" true \
#			| . "${ARKLONE[installDir]}/dialogs/gauges/systemd/generate-retroarch-units.sh"

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/config.sh"

# Array of supported retroarch.cfg settings
FILETYPES=("savefile" "savestate")

# Get all retroarch.cfg instances
RETROARCHS=(${ARKLONE[retroarchCfg]})

# Wait for main script to begin editing ${RETROARCHS[0]}
while read line; do
    if grep -E "^Now processing: .*retroarch.cfg$" <<<"${line}" >/dev/null 2>&1; then
        break
    fi
done

# Loop through retroarch.cfg instances
for i in "${!RETROARCHS[@]}"; do
    # Store retroarch.cfg settings in an array
    declare -A r
    loadConfig "${RETROARCHS[$i]}" r "$(tr ' ' '|' <<<"${FILETYPES[@]}")"

    # Loop through supported retroarch.cfg settings
    for j in "${!FILETYPES[@]}"; do
        # Get array of path unit directories
        if [[ "${r[${FILETYPES[$j]}s_in_content_dir]}" = "true" ]]; then
            directories=($(find "${ARKLONE[retroarchContentRoot]}" -mindepth 1 -maxdepth 1 -type d))

        elif
            [[ "${r[sort_${FILETYPES[$j]}s_by_content_enable]}" = "false" ]] \
            && [[ "${r[sort_${FILETYPES[$j]}s_enable]}" = "false" ]]
        then
            directories=("${r[${FILETYPES[$j]}_directory]}")

        elif [[ "${r[sort_${FILETYPES[$j]}s_by_content_enable]}" != "${r[sort_${FILETYPES[$j]}s_enable]}" ]]; then
            directories=($(find "${r[${FILETYPES[$j]}_directory]}" -mindepth 1 -maxdepth 1 -type d))

        else
            directories=($(find "${r[${FILETYPES[$j]}_directory]}" -mindepth 2 -maxdepth 2 -type d))
        fi

        # Get total number of path units to create
        totalUnits=$(( ${#directories[@]} * ${#FILETYPES[@]} * ${#RETROARCHS[@]} ))

        # Continue reading from script output
        while read line; do
            # Main script is now processing ${RETROARCHS[(($i + 1))]}
            if grep -E "^Now processing: .*retroarch.cfg$" <<<"${line}" >/dev/null 2>&1; then
                break

            # Main script is now processing ${FILETYPES[(($j + 1))]}
            elif
                [[ ${FILETYPES[(( $j + 1 ))]} ]] \
                && grep "${FILETYPES[(( $j + 1 ))]}" <<<"${line}" >/dev/null 2>&1
            then
                break

            # Main script is creating a path unit
            elif grep "Creating " <<<"${line}" >/dev/null 2>&1; then
                # Get path unit's instance name
                instance=$(sed -e 's|Creating instance: ||' -e 's| at .*$||' <<<"${line}")
                # Get local directory
                IFS="@" read -r localdir remotedir filters <<<"${instance}"

                # Get directory's index from ${directories}
                # and calculate progress percentage
                for k in "${!directories[@]}"; do
                    if [[ "${directories[$k]}" = "${localdir}" ]]; then
                        curUnit=$(( $k + ( $j * ${#directories[@]} ) + ( $i * ${#directories[@]} * ${#RETROARCHS[@]} )))
                        echo $(( ( $curUnit * 100 ) / $totalUnits ))
                    fi
                done

            # Main script is skipping path unit
            elif grep "Skipping." <<<"${line}" >/dev/null 2>&1; then
                # Get local directory
                localdir=$(sed -e 's/A path unit for //' -e 's/ using .* already exists. Skipping.$//' <<<"${line}")

                # Get directory's index from ${directories}
                # and calculate progress percentage
                for k in "${!directories[@]}"; do
                    if [[ "${directories[$k]}" = "${localdir}" ]]; then
                        curUnit=$(( $k + ( $j * ${#directories[@]} ) + ( $i * ${#directories[@]} * ${#RETROARCHS[@]} )))
                        echo $(( ( $curUnit * 100 ) / $totalUnits ))
                    fi
                done
            fi
        done
    done

    # Unset r to prevent conflicts on next loop
    unset r
done | whiptail \
    --title "${ARKLONE[whiptailTitle]}" \
    --gauge "Generating retroarch path units..." \
    16 56 \
    0
