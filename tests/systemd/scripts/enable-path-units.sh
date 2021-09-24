#!/bin/bash
source "/opt/arklone/config.sh"

# Mock enabled units
ARKLONE[unitsDir]="/dev/shm/units"
ARKLONE[autoSync]=""

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
if systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	sudo systemctl disable "arkloned@.service"
fi

if systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	sudo systemctl disable "arkloned-receive-saves-boot.service"
fi

# Enable path units
. "${ARKLONE[installDir]}/systemd/scripts/enable-path-units.sh"

# Service template unit is linked
if ! systemctl list-unit-files "arkloned@.service" | grep "linked"; then
	exit 78
fi

# Path unit is enabled
if ! systemctl list-unit-files "arkloned-test.path" | grep "enabled"; then
	exit 78
fi

# Boot service is enabled
if ! systemctl list-unit-files "arkloned-receive-saves-boot.service" | grep "enabled"; then
	exit 78
fi

# Teardown
rm -rf "/dev/shm/foo"
rm -rf "${ARKLONE[unitsDir]}"
