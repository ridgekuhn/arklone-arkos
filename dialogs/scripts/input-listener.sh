#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Listen to input and convert to keycodes for command input
#
# Uses oga_controls
# @see https://github.com/christianhaitian/oga_controls
#
# @param $1 Absolute path to the command to run

[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

RUNCOMMAND="${1}"

# Get device type
# Anbernic RG351x
if [ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]; then
  PARAM_DEVICE="anbernic"

# ODROID Go 2
elif [ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]; then
    if [ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]; then
      PARAM_DEVICE="oga"
    else
      PARAM_DEVICE="rk2020"
    fi

# ODROID Go 3
elif [ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]; then
  PARAM_DEVICE="ogs"

# Gameforce Chi
elif [ -e "/dev/input/by-path/platform-gameforce-gamepad-event-joystick" ]; then
  PARAM_DEVICE="chi"
fi

if [ $PARAM_DEVICE ]; then
    # Change to bundled oga_controls directory
    # so it can find oga_controls_settings.txt
    cd "${ARKLONE[installDir]}/vendor/oga_controls"

    # Run oga_controls in the background
    sudo ./oga_controls "${RUNCOMMAND}" "${PARAM_DEVICE}" &
fi

# Run/source the command in a subshell so it has access to ${ARKLONE[@]}
# but can still use `exit` without exiting this script
(. "${RUNCOMMAND}")

EXIT_CODE=$?

# Teardown
if [ $PARAM_DEVICE ]; then
    sudo kill -s SIGKILL $(pidof oga_controls)
fi

exit $EXIT_CODE

