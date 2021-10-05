#!/bin/bash
# arklone cloud sync utility
# by ridgek
# Released under GNU GPLv3 license, see LICENSE.md.

source "/opt/arklone/config.sh"

###########
# MOCK DATA
###########
# Unlink conflicting real units
sudo systemctl disable "arkloned@.service"
sudo systemctl disable "arkloned-receive-saves-boot.service"

# Mock watched path
mkdir "/dev/shm/foo"

# Mock enabled units
ARKLONE[unitsDir]="/dev/shm/units"
mkdir "${ARKLONE[unitsDir]}"

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

sudo systemctl link "${ARKLONE[unitsDir]}/arkloned@.service"
sudo systemctl enable "${ARKLONE[unitsDir]}/arkloned-test.path"
sudo systemctl enable "${ARKLONE[unitsDir]}/arkloned-receive-saves-boot.service"

# Populate ${ARKLONE[enabledUnits]}
ARKLONE[enabledUnits]="arkloned@.service arkloned-test.path arkloned-receive-saves-boot.service"

#####
# RUN
#####
. "${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh"

[ $? = 0 ] || exit $?

########
# TEST 1
########
# Service template unit is not linked
if systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	exit 78
fi

echo "TEST 1 passed."

########
# TEST 2
########
# Path unit is disabled
if systemctl list-unit-files "arkloned-test.path" | grep "enabled"; then
	exit 78
fi

echo "TEST 2 passed."

########
# TEST 3
########
# Boot service is disabled
if systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	exit 78
fi

echo "TEST 3 passed."

##########
# TEARDOWN
##########
rm -rf "/dev/shm/foo"
rm -rf "${ARKLONE[unitsDir]}"

