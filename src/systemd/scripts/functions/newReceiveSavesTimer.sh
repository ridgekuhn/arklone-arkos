#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

# Create a new systemd timer to call arkloned-receive-saves.service
#
# @param $1 {integer} Number of seconds to wait to activate unit
function newReceiveSavesTimer() {
    local seconds="${1}"

    local unit="${ARKLONE[unitsDir]}/arkloned-receive-saves.timer"

    # Remote old unit
    [[ -f "${unit}" ]] && rm -f "${unit}"

    # Do not make unit if ${seconds} is 0
    if [[ "${seconds}" = 0 ]]; then
        return
    fi

    # Create new unit
    cat <<EOF >"${unit}"
[Unit]
Description=arklone - receive saves timer

[Timer]
OnBootSec=${seconds}
OnUnitActiveSec=${seconds}

[Install]
WantedBy=timers.target
EOF
}

