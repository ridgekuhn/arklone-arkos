#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

# Print a list of enabled systemd units
#
# @returns 1 if no enabled units
function getEnabledUnits() {
	systemctl list-unit-files arkloned* | grep -E "enabled|linked" | cut -d " " -f 1 || exit 1
}
