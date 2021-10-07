# arklone developer docs #

arklone should be installed at `/opt/arklone`

---

**Table of Contents**

1. [systemd Units](#systemd-units)
    * [arkloned@.service Template](#arklonedservice-template)
    * [Path Units](#path-units)
    * [rclone Filters](#rclone-filters)
    * [Watching Recursively with inotifywait](#recursive-watching-with-inotifywait)

2. [rclone Scripts](#rclone-scripts)

3. [API](#api)
    * [${ARKLONE[@]}](#arklone)
    * [arklone.cfg](#arklone-cfg)
    * [Load User Config](#load)
    * [Edit User Config](#edit)
    * [Create a New Path Unit](#create-a-new-path-unit)
    * [Create Path Units from a Directory](#create-path-units-from-a-directory)
    * [Wrapper to Kill a Script on Keypress](#wrapper-to-kill-a-script-on-keypress)
    * [Wrapper to Accept Gamepad Input for Interactive Programs](#wrapper-to-accept-gamepad-input-for-interactive-programs)
    * [Logging](#logging)
    * [Dialogs](#dialogs)
    * [Dirty Boot State](#dirty-boot-state)
    * [Other](#other)

---

## systemd Units ##

arklone uses systemd path units for watching directories and launching scripts. Path units are stored in [systemd/units/](/systemd/units). 

### arkloned@.service Template ###

[arkloned@.service](/systemd/units/arkloned@.service) launches [send-and-receive-saves.sh](/rclone/scripts/send-and-receive-saves.sh), passing the instance name from path units as arguments.

**arkloned@.service**

```
ExecStart=/bin/bash -c "/opt/arklone/rclone/scripts/send-and-receive-saves.sh %I"
```

### Path Units ###

Path units can be created manually, and should be placed in [systemd/units](/systemd/units). Filenames should end in `.path`. Do not use `.auto.path`, or `.sub.auto.path`, as these are reserved by arklone (see [Create Path Units from a Directory](#create-path-units-from-a-directory) and [newPathUnitsFromDir](/systemd/scripts/functions/newPathUnitsFromDir.sh)).

To utilize the `arkloned@.service` template, `Unit=` name must be prefixed with `arkloned@`, be escaped using `systemd-escape`, and end with `.service`.

The instance name format is:

```
/path/to/local_directory@remote_directory@filters
```

* `remote_directory` can be a subdirectory, eg, `parent_dir/child_dir`, but it should not contain leading or trailing slashes.

* Multiple filters can be passed with pipe-delimiting:
`filter1|filter2|filter3`

* Pass only the name of the filter, no extension. Default filter files are stored in [rclone/filters] (rclone/filters).

**example retroarch.path unit**
For unescaped instance name `/home/user/.config/retroarch/saves@retroarch/saves@retroarch-savefile|retroarch-savestate`:

```
[Path]
PathChanged=/home/user/.config/retroarch/saves
Unit=arkloned@-home-user-.config-retroarch-saves\x40retroarch-saves\x40retroarch\x2dsavefile\x7cretroarch\x2dsavestate.service

[Install]
WantedBy=multi-user.target
```

Path units can also be generated programmatically using [newPathUnit](systemd/scripts/functions/newPathUnit.sh) or [newPathUnitsFromDir](systemd/scripts/functions/newPathUnitsFromDir.sh) in a script. See below, or see [generate-retroarch-units.sh](systemd/scripts/generate-retroarch-units.sh) for an example.

### rclone Filters ###

Filters in the path unit's instance name are a pipe-delimited list used for passing to `rclone`'s `--filter-from` option. They should be placed in [rclone/filters](rclone/filters).

**cavestory.filter**

```
+ profile.dat
+ settings.dat
- *
```

### Ignoring Units when Automatic Syncing is Enabled ###

To prevent a systemd path unit or service from being enabled when the user selects automatic syncing, add the name of the unit to [systemd/scripts/ignores/autosync.ignore](/systemd/scripts/ignores/autosync.ignore).

### Watching Recursively with inotifywait ###

Unforunately, systemd path units are not currently capable of recursively watching a directory. In this case, [watch-directory.sh](/systemd/scripts/inotify/watch-directory.sh) is provided as a workaround (to call the [arkloned@.service](/systemd/units/arkloned@.service) template, as would normally be done by the path unit), and should be called from a custom systemd service unit. If the custom service unit is placed in [systemd/units](/systemd/units), it will automatically be enabled when [enable-path-units.sh](/systemd/scripts/enable-path-units.sh) is run. A corresponding path unit must still be created.

[watch-directory.sh](/systemd/scripts/inotify/watch-directory.sh) takes two or more arguments. The first parameter is the path to the corresponding systemd path unit, and should be called in the `ExecStart=` line of the service unit file. The second argument and beyond are patterns to exclude from `inotifywait`, as regular expression strings.

[arkloned-ppsspp.service](/systemd/units/arkloned-ppsspp.service):

```
[Unit]
Description=arklone - ppsspp sync service
Requires=network-online.target arkloned-receive-saves-boot.service
After=network-online.target arkloned-receive-saves-boot.service

[Service]
Type=simple
ExecStart=/bin/bash -c '/opt/arklone/systemd/scripts/inotify/watch-directory.sh "/opt/arklone/systemd/units/arkloned-ppsspp.path" "/SYSTEM/"'

[Install]
WantedBy=multi-user.target
```

[arkloned-ppsspp.path](/systemd/units/arkloned-ppsspp.path):

```
[Path]
PathChanged=/home/ark/.config/ppsspp
Unit=arkloned@-home-ark-.config-ppsspp\x40ppssppx40ppsspp.service

[Install]
WantedBy=multi-user.target
```

To prevent the path unit from being enabled in systemd when [enable-path-units.sh](/systemd/scripts/enable-path-units.sh) is run, add the name of the path unit to the `systemd/scripts/ignores/autosync.ignore` file.

[autosync.ignore](/systemd/scripts/ignores/autosync.ignore)

```
arkloned-ppsspp.path
```

---

## rclone Scripts ##

### receive-saves.sh ###

[receive-saves.sh](/rclone/scripts/receive-saves.sh) *receives from the cloud only, overwriting older local data*. This script is called by [arkloned-receive-saves-boot.service](/systemd/units/arkloned-receive-saves-boot.service).

Since `rclone` is capable of recursing an entire directory, this script scans the [systemd/units](/systemd/units) directory for "root" path units only (files ending in `.path` or `.auto.path`, but not `sub.auto.path`) and syncs the corresponding directory. The `.sub.auto.path` units only exist because systemd is not capable of recursively watching a directory, so these units do not need to be utilized for this process.

See [Create Path Units from a Directory](#create-path-units-from-a-directory) and [newPathUnitsFromDir](/systemd/scripts/functions/newPathUnitsFromDir.sh) for how `.auto.path` and `.sub.auto.path` units are generated).

### send-and-receive-saves.sh ###

[send-and-receive-saves.sh](/rclone/scripts/send-and-receive-saves.sh) requires being called with the unescaped instance name of a path unit, in the format `${LOCALDIR}@${REMOTEDIR}@${FILTERS}`, where:
* "${LOCALDIR} is an absolute path, no trailing slash"
* "${REMOTEDIR} has no opening or trailing slashes"
* "${FILTERS}" is a pipe-delimited list of [rclone filters](#rclone-filters)

This script *sends first, overwriting older cloud data*, then receives any missing or newer data from the cloud.

### send-arkos-backup.sh ###

[send-arkos-backup.sh](/rclone/scripts/send-arkos-backup.sh) runs the ArkOS backup script, and then sends it to the cloud remote, storing it in its own directory, `ArkOS/`.

---

## API ##

### ${ARKLONE[@]} and arklone.cfg ###

The `${ARKLONE[@]}` array contains various information about the state of the application. This includes certain filepaths and whether arklone's systemd units are enabled. 

#### ${ARKLONE[@]} ####

Defaults are defined in [config.sh](config.sh).

To access `${ARKLONE[@]}` in your script, source config.sh:

```shell
#!/bin/bash
source "/opt/arklone/config.sh"

# Echo the logfile path
echo "${ARKLONE[log]}"

# Print a list of enabled arklone systemd units
tr ' ' '\n' <<<"${ARKLONE[enabledUnits]}"
```

If your script can run directly from the command line, or be `source`d in another script where ${ARKLONE[@]} is already defined:

**say-good-morning.sh**

```shell
#!/bin/bash
# Only source config.sh if "${ARKLONE[@]} is unpopulated"
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

echo "Good morning! Your configuration is stored at: ${ARKLONE[userCfg]}"
```

**wake-up.sh**

```shell
#!/bin/bash
# Load ${ARKLONE[@]}
source "/opt/arklone/config.sh"

# Do morning routine
if [ "${ARKLONE[remote]}" = "dropbox" ]; then
	sleep 1

	# Sub-shell does not have access to ${ARKLONE[@]}
	/path/to/wakeup.sh

	# Has access to ${ARKLONE[@]}
	. /path/to/say-good-morning.sh
fi
```

#### arklone.cfg ####

`${ARKLONE[@]}` also has access to user preferences stored in `~/.config/arklone/arklone.cfg`. This includes information like the path to the user's `retroarch.cfg`, and which remote to sync with.

A default copy of the file is stored in [arklone.cfg.orig](arklone.cfg.orig).

**~/.config/arklone/arklone.cfg**

```
some_setting = "true"
```

**your script**

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"

echo "User set some_setting to "${ARKLONE[some_setting]}"
```

---

### Handling User Configurations ###

#### Load ####

[loadConfig](functions/loadConfig.sh) reads a configuration file into an array.

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t loadConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/loadConfig.sh"

# Create an array to store some values
declare -A MY_CONFIG

loadConfig "/path/to/myconfig.cfg" MY_CONFIG

echo "${MY_CONFIG[foo]}"
```

#### Edit ####

[editConfig](functions/editConfig.sh) sets a value into a configuration file.

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t editConfig)" = "function" ] || source "${ARKLONE[installDir]}/functions/editConfig.sh"

editConfig "bar" "false" "/path/to/myconfig.cfg"

declare -A MY_CONFIG
loadConfig "/path/to/myconfig.cfg" MY_CONFIG "bar"

echo "${MY_CONFIG[bar]}"
```

---

### Generating Path Units ###

#### Create a New Path Unit ####

Path units can be generated with [newPathUnit](systemd/scripts/functions/newPathUnit.sh).

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t newPathUnit)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnit.sh"

newPathUnit "retroarch-saves" "/home/user/.config/retroarch/saves" "retroarch/saves" "retroarch-savefile"
```

#### Create Path Units from a Directory ####

Multiple path units can be made from a directory and a specified depth of subdirectories with [newPathUnitsFromDir](systemd/scripts/functions/newPathUnitsFromDir.sh).

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t newPathUnitsFromDir)" = "function" ] || source "${ARKLONE[installDir]}/systemd/scripts/functions/newPathUnitsFromDir.sh"

newPathUnitsFromDir "/path/to/roms" "retroarch/roms" 1 true "retroarch-savefile|retroarch-savestate" "/path/to/list-of-dirs-to.ignore"
```

`.ignore` files are simple line-delimited lists of patterns to check against the name of the subdirectory, and should be placed in [systemd/scripts/ignores](systemd/scripts/ignores). A [global ignore list](systemd/scripts/ignores/global.ignore) is also used to check subdirectories against, and contains unwanted items like `.DS_Store`, `.Trashes`, etc.

---

### Wrapper to Kill a Script on Keypress ###

[killOnKeyPress](functions/killOnKeyPress.sh) runs a command and allows the user to kill the process by pressing any key. Along with [oga_controls](#wrapper-to-accept-gamepad-input-for-interactive-programs), this is useful for letting the user quit a process when their only connected input device is a gamepad.

```shell
#!/bin/bash
source "/opt/arklone/config.sh"
source "${ARKLONE[installDir]}/functions/killOnKeyPress.sh"

killOnKeyPress "/path/to/my/script.sh"
```

---

### Wrapper to Accept Gamepad Input for Interactive Programs ###

[oga_controls](/vendor/oga_controls) ([source](https://github.com/christianhaitian/oga_controls)) converts gamepad input to key codes and mouse input data. [A wrapper script](/dialogs/input-listener.sh) is provided to automatically detect the input device and execute a command passed to it.

```shell
/opt/arklone/dialogs/input-listener.sh "/path/to/my/script.sh"
```

---

### Logging ###

By default, arklone logs to the RAM filesystem at `/dev/shm/arklone.log`. This path can be set by the user and is available at `${ARKLONE[log]}`.

To use arklone's logger, run [arkloneLogger](functions/arkloneLogger.sh). All stdout/stderr will be logged to the log file until the process that called `arkloneLogger` quits.

```shell
#!/bin/bash
[ ${#ARKLONE[@]} -gt 0 ] || source "/opt/arklone/config.sh"
[ "$(type -t arkloneLogger)" = "function" ] || source "${ARKLONE[installDir]}/functions/arkloneLogger.sh"

arkloneLogger "${ARKLONE[log]}"

echo "Hello, world!"
```

---

### Dialogs ###

Dialogs use `whiptail` and should be limited to acting as "views" whenever possible. Any non-trivial operations should be contained to functions or standalone scripts when possible.

[dialogs/settings.sh](dialogs/settings.sh):

```shell
#!/bin/bash
# Enable/Disable auto savefile/savestate syncing
function autoSyncSavesScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--infobox \
			"Please wait while we configure your settings..." \
			16 56 8

	# Enable or disable path units
	local enabledUnits=(${ARKLONE[enabledUnits]})

	if [ "${#enabledUnits[@]}" = 0 ]; then
		. "${ARKLONE[installDir]}/systemd/scripts/enable-path-units.sh"
	else
		. "${ARKLONE[installDir]}/systemd/scripts/disable-path-units.sh"
	fi

	# Reset ${ARKLONE[enabledUnits]}
	ARKLONE[enabledUnits]=$(getEnabledUnits)

	homeScreen
}
```

---

### Dirty Boot State ###

After boot, but before EmulationStation starts, arklone checks for a network connection and attempts to receive any new updates from the configured remote. It does not send any data back until a file has been written on the device. This ensures that the cloud copy is the canonical and "always correct" one. 

If this process fails at any point, the dirtyboot state is set. Automatic syncing is disabled for the rest of the session, and the user will be warned about potential data loss on the following boot.

To manually reset the dirtyboot state, delete the lock file located at:
`~/.config/arklone/.dirtyboot`

For scripting, the path to `.dirtyboot` is available in `${ARKLONE[dirtyBoot]}`.

---

### Other ###

Please refer to the inline documentation for other functions and scripts.

