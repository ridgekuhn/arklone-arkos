#!/bin/bash
source "/opt/arklone/config.sh"

# Mock enabled units
ARKLONE[unitsDir]="/dev/shm/units"
ARKLONE[autoSync]="arkloned-test.path"

mkdir "${ARKLONE[unitsDir]}"
mkdir "/dev/shm/foo"

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

# Unlink conflicting real units
sudo systemctl disable "arkloned@.service"
sudo systemctl disable "arkloned-receive-saves-boot.service"

sudo systemctl link "${ARKLONE[unitsDir]}/arkloned@.service"
sudo systemctl enable "${ARKLONE[unitsDir]}/arkloned-test.path"
sudo systemctl enable "${ARKLONE[unitsDir]}/arkloned-receive-saves-boot.service"

# Disable path units
. "${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh"

# Service template unit is not linked
if systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	exit 78
fi

# Path unit is disabled
if systemctl list-unit-files "arkloned-test.path" | grep "enabled"; then
	exit 78
fi

# Boot service is disabled
if systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	exit 78
fi

# Teardown
rm -rf "/dev/shm/foo"
rm -rf "${ARKLONE[unitsDir]}"
