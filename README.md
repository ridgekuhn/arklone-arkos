# arklone #
rclone cloud syncing for ArkOS

---

This module contains three parts:
* A standalone script which syncs two directories using rclone
* A standalone script which syncs the ArkOS settings backup to the cloud
* A systemd service for monitoring RetroArch savefile/savestate directories
* A whiptail frontend for the script and service above

### arklone-saves.sh ###
Syncs two directories using rclone

Executed by:
* [arkloned@.service template]() when a corresponding _arkloned-*.path_ unit is started.
* [settings.sh]() via EmulationStation
* Manually

To execute manually, pass two directories as a string to the first argument,
in the format `localDir@remoteDir@filter`.

`filter` refers to a .filter file in `arklone/rclone/filters`

_Do not use trailing slashes. The remote directory also must not have an opening slash._

```shell
$ /opt/arklone/arklone.sh "/roms@retroarch/roms@retroarch-savefiles"

```

### arklone-arkos.sh ###
Calls the ArkOS backup script and syncs the resulting file to the cloud.

Executed by:
* [settings.sh]() See below

### systemd units ###
Four path units are provided to the [arkloned@.service]() template:

* /opt/amiberry/savestates@amiberry/savestates
* /roms@retroarch/roms
* /home/ark/.config/retroarch/saves@retroarch/saves
* /home/ark/.config/retroarch/states@retroarch/states

To watch a directory, create a new file at `/opt/arkloned/systemd/arkloned-${myPathUnit}.path`. Only 3 lines are needed:

```shell
[Path]
PathChanged=/path/to/watch
Unit=arkloned@-path-to-watch\x40path-to-sync-to
```

The `Unit` name should be prefixed with `arkloned@`, followed by
an escaped string containing the directories to sync,
in the format `localDir@remoteDir@filter`,
where `filter` is an optional rclone `.filter` file contained in
`arklone/rclone/filters`. The filter is optional, but the 
string must containing the preceding `@`. Do not use trailing slashes for paths.
The remote directory must also not have an opening slash.

You can generate an escaped directory string using the `systemd-escape` tool:

```shell
$ systemd-escape "/path/to/watch@path/to/sync/to@myFilter"
# outputs:
# -path-to-watch\x40path-to-sync-to\x40myFilter
```

[settings.sh]() will automatically handle enabling and starting the path unit when the user enables automatic syncing.

### settings.sh ###
Four whiptail options are provided initially:
* Set cloud service
* Manual sync savefiles/savestates
* Enable/Disable automatic syncing
* Manual sync ArkOS Settings
