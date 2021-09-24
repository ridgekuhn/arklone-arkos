#!/bin/bash
source "/opt/arklone/config.sh"

# Check if config array loaded correctly
[ "${#ARKLONE[@]}" -gt 0 ] || exit 70
