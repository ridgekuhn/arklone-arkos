#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Unlink conflicting real units
if systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	sudo systemctl disable "arkloned@.service"
fi

if systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	sudo systemctl disable "arkloned-receive-saves-boot.service"
fi

# Mock enabled units
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

# Mock watched path
mkdir "/dev/shm/foo"
mkdir "/dev/shm/ppsspp"

cat <<EOF > "${ARKLONE[unitsDir]}/arkloned-test.path"
[Path]
PathChanged=/dev/shm/foo
Unit=arkloned@-dev-shm-foo\x40remotedir\x40filter.service

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > "${ARKLONE[unitsDir]}/arkloned@.service"
[Unit]
Wants=multi-user.target

[Service]
Type=oneshot
StandardOutput=journal+console
ExecStart=/bin/bash -c "echo instance is %I"

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > "${ARKLONE[unitsDir]}/arkloned-receive-saves-boot.service"
[Unit]
Wants=multi-user.target

[Service]
Type=oneshot
StandardOutput=journal+console
ExecStart=/bin/bash -c "echo instance is %I"

[Install]
WantedBy=multi-user.target
EOF

# Mock unit in "${ARKLONE[installDir]}/systemd/scripts/ignores/autosync.ignore" list
cat <<EOF > "${ARKLONE[unitsDir]}/arkloned-ppsspp.path"
[Path]
PathChanged=/dev/shm/ppsspp
Unit=arkloned@-dev-shm-ppsspp\x40remotedir\x40filter.service

[Install]
WantedBy=multi-user.target
EOF

#####
# RUN
#####
. "${ARKLONE[installDir]}/systemd/scripts/enable-path-units.sh"

########
# TEST 1
########
# Service template unit is linked
if ! systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	exit 78
fi

echo "TEST 1 passed."

########
# TEST 2
########
# Path unit is enabled
if ! systemctl list-unit-files "arkloned-test.path" | grep "enabled"; then
	exit 78
fi

echo "TEST 2 passed."

########
# TEST 3
########
# Boot service is enabled
if ! systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	exit 78
fi

echo "TEST 3 passed."

########
# TEST 4
########
# Ignored units were not enabled
IGNORED_UNITS=($(cat "${ARKLONE[ignoreDir]}/autosync.ignore"))

for unit in ${IGNORED_UNITS[@]}; do
	systemctl list-unit-files | grep "${unit}"
	if systemctl list-unit-files | grep "${unit}"; then
		exit 78
	fi
done

echo "TEST 4 passed."

##########
# TEARDOWN
##########
"${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh"

rm -rf "/dev/shm/foo"
rm -rf "/dev/shm/ppsspp"
rm -rf "${ARKLONE[unitsDir]}"

