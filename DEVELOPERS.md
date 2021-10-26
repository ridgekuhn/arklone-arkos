# arklone developer docs #

arklone should be installed at `/opt/arklone`

Submissions must follow the [RetroPie Shell Style Guide](https://retropie.org.uk/docs/Shell-Style-Guide/).

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

&nbsp;

---

# systemd Units #

arklone uses systemd path units for watching directories and launching scripts. Path units are stored in [systemd/units/](/systemd/units). 

## arkloned@.service Template ##

[arkloned@.service](/systemd/units/arkloned@.service) launches [send-and-receive-saves.sh](/rclone/scripts/send-and-receive-saves.sh), passing the path unit's instance name as an argument. **The service template sends data only.**

&nbsp;

**arkloned@.service:**

```
ExecStart=/opt/arklone/src/rclone/scripts/send-and-receive-saves.sh "send" %I
```


## Path Units ##

Path units can be created manually, and should be placed in [systemd/units](/systemd/units). Filenames should end in `.path`. Do not use `.auto.path`, or `.sub.auto.path`, as these are reserved by arklone (see [Create Path Units from a Directory](#create-path-units-from-a-directory) and [newPathUnitsFromDir](/systemd/scripts/functions/newPathUnitsFromDir.sh)).

To utilize the `arkloned@.service` template, `Unit=` name must be prefixed with `arkloned@`, with the instance name escaped using `systemd-escape`, and end with `.service`.

The instance name format is:

```
/path/to/local_directory@remote_directory@filters
```

* `remote_directory` can be a directory tree, eg, `parent_dir/child_dir`, but it should not contain leading or trailing slashes.

* Multiple filters can be passed with pipe-delimiting: `filter1|filter2|filter3`

* Pass only the name of the filter, no extension. Default filter files are stored in [rclone/filters](rclone/filters).

&nbsp;

**example retroarch.path unit:**

```
# Unescaped instance name: /home/user/.config/retroarch/saves@retroarch/saves@retroarch-savefile|retroarch-savestate

[Path]
PathChanged=/home/user/.config/retroarch/saves
Unit=arkloned@-home-user-.config-retroarch-saves\x40retroarch-saves\x40retroarch\x2dsavefile\x7cretroarch\x2dsavestate.service

[Install]
WantedBy=multi-user.target
```

Path units can also be generated programmatically using [newPathUnit](systemd/scripts/functions/newPathUnit.sh) or [newPathUnitsFromDir](systemd/scripts/functions/newPathUnitsFromDir.sh) in a script. See below, or see [generate-retroarch-units.sh](systemd/scripts/generate-retroarch-units.sh) for an example.

## rclone Filters ##

Filters in the path unit's instance name are a pipe-delimited list used for passing to `rclone`'s `--filter-from` option. They should be placed in [rclone/filters](rclone/filters).

&nbsp;

**cavestory.filter:**

```
+ profile.dat
+ settings.dat
- *
```

## Ignoring Units when Automatic Syncing is Enabled ##

To prevent a systemd path unit or service from being enabled when the user selects automatic syncing, add the name of the unit to [systemd/scripts/ignores/autosync.ignore](/systemd/scripts/ignores/autosync.ignore).

## Watching Recursively with inotifywait ##

Unforunately, systemd path units are not currently capable of recursively watching a directory. In this case, [watch-directory.sh](/systemd/scripts/inotify/watch-directory.sh) is provided as a workaround (to call the [arkloned@.service](/systemd/units/arkloned@.service) template, as would normally be done by the path unit), and should be called from a custom systemd service unit.

If the custom service unit is placed in [systemd/units](/systemd/units), it will automatically be enabled when [enable-path-units.sh](/systemd/scripts/enable-path-units.sh) is run. A corresponding path unit must still be created.

[watch-directory.sh](/systemd/scripts/inotify/watch-directory.sh) takes two or more arguments. The first parameter is the path to the corresponding systemd path unit, and should be called in the `ExecStart=` line of the service unit file. The second argument and beyond are patterns to exclude from `inotifywait`, as regular expression strings.

&nbsp;

[arkloned-ppsspp.service](/systemd/units/arkloned-ppsspp.service):

```
[Unit]
Description=arklone - ppsspp sync service
Requires=network-online.target arkloned-receive-saves-boot.service
After=network-online.target arkloned-receive-saves-boot.service

[Service]
Type=simple
ExecStart=/opt/arklone/src/systemd/scripts/inotify/watch-directory.sh "/opt/arklone/src/systemd/units/arkloned-ppsspp.path" "/SYSTEM/"

[Install]
WantedBy=multi-user.target
```

&nbsp;

[arkloned-ppsspp.path](/systemd/units/arkloned-ppsspp.path):

```
[Path]
PathChanged=/home/ark/.config/ppsspp
Unit=arkloned@-home-ark-.config-ppsspp\x40ppssppx40ppsspp.service

[Install]
WantedBy=multi-user.target
```


To prevent the path unit from being enabled in systemd when [enable-path-units.sh](/systemd/scripts/enable-path-units.sh) is run, add the name of the path unit to the `systemd/scripts/ignores/autosync.ignore` file.

&nbsp;

[autosync.ignore](/systemd/scripts/ignores/autosync.ignore)

```
arkloned-ppsspp.path
```

&nbsp;

---

# rclone Scripts #

## sync-one-dir.sh ##

[sync-one-dir.sh](/rclone/scripts/sync-one-dir.sh) syncs a single path unit's directory. Takes two arguments; send or receive, and the path unit's instance name.

## sync-all-dirs.sh ##

[sync-all-dirs.sh](/rclone/scripts/sync-all-dirs.sh) syncs all path units' directories. Takes a single argument, send or receive.

Since `rclone` is capable of recursing an entire directory, this script scans the [systemd/units](/systemd/units) directory for "root" path units only (files ending in `.path` or `.auto.path`, but not `sub.auto.path`) and syncs each corresponding directory. (The `.sub.auto.path` units only exist because systemd is not capable of recursively watching a directory, so these units do not need to be utilized by this script. See [Create Path Units from a Directory](#create-path-units-from-a-directory) and [newPathUnitsFromDir](/systemd/scripts/functions/newPathUnitsFromDir.sh) for how `.auto.path` and `.sub.auto.path` units are generated.)

## send-arkos-backup.sh ##

[send-arkos-backup.sh](/rclone/scripts/send-arkos-backup.sh) runs the ArkOS backup script, and then sends it to the cloud remote, storing it in its own directory, `ArkOS/`.

&nbsp;

---

# API #

## ${ARKLONE[@]} and arklone.cfg ##

The `${ARKLONE[@]}` array contains various information about the state of the application. This includes certain filepaths and whether arklone's systemd units are currently enabled. 

### ${ARKLONE[@]} ###

Defaults are defined in [config.sh](config.sh).

To access `${ARKLONE[@]}` in your script, `source` config.sh:

```shell
#!/bin/bash
source "/opt/arklone/src/config.sh"

# Echo the logfile path
echo "${ARKLONE[log]}"

# Print a list of enabled arklone systemd units
tr ' ' '\n' <<<"${ARKLONE[enabledUnits]}"
```

If your script can run directly from the command line, *or* `source`d in another script where ${ARKLONE[@]} is already defined:

&nbsp;

**say-good-morning.sh**

```shell
#!/bin/bash
# Only source config.sh if "${ARKLONE[@]} is unpopulated"
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

echo "Good morning! Let's eat ${ARKLONE[food]} for breakfast."
```

&nbsp;

**wake-up.sh**

```shell
#!/bin/bash
# Load ${ARKLONE[@]}
source "/opt/arklone/src/config.sh"

# Do morning routine
if [[ "${ARKLONE[remote]}" = "dropbox" ]]; then
	sleep 1

	# Set breakfast food
	ARKLONE[food]="pancakes"

	# Child process does not have access to ${ARKLONE[food]}
	/path/to/turn-off-alarm.sh

	# Sourced (.) script has access to ${ARKLONE[food]}
	. /path/to/say-good-morning.sh

	# Sourced (.) sub-shell script  has access to ${ARKLONE[food]}
	# Running in sub-shell allows sourced script to use
	# the `exit` command without exiting this script
	(. /path/to/make-breakfast.sh)
fi
```

### arklone.cfg ###

`${ARKLONE[@]}` also has access to user preferences stored in `~/.config/arklone/arklone.cfg`. This includes information like the path to the user's `retroarch.cfg`, and the user's chosen rclone remote.

A default copy of the file is stored in [arklone.cfg.orig](arklone.cfg.orig).

&nbsp;

**~/.config/arklone/arklone.cfg**

```
some_setting = "true"
```

&nbsp;

**your script**

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"

echo "User set some_setting to "${ARKLONE[some_setting]}"
```

&nbsp;

---

## Handling User Configurations ##

### Load ###

[loadConfig](functions/loadConfig.sh) reads a configuration file into an array. Depending on who runs the script, tildes `~` are expanded to `/home/${SUDO_USER}`, `/home/${USER}`, or `/home/(name of user with uid 1000)`, in that order. **The config.sh script also sets `$USER` to the respective user.**

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t loadConfig)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/loadConfig.sh"

# Create an array to store some values
declare -A MY_CONFIG

loadConfig "/path/to/myconfig.cfg" MY_CONFIG

echo "${MY_CONFIG[foo]}"
```

### Edit ###

[editConfig](functions/editConfig.sh) sets a value into a configuration file.

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t editConfig)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/editConfig.sh"

editConfig "bar" "false" "/path/to/myconfig.cfg"

declare -A MY_CONFIG
loadConfig "/path/to/myconfig.cfg" MY_CONFIG "bar"

echo "${MY_CONFIG[bar]}"
```

&nbsp;

---

## Generating Path Units ##

### Create a New Path Unit ###

Path units can be generated with [newPathUnit](systemd/scripts/functions/newPathUnit.sh).

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t newPathUnit)" = "function" ]] || source "${ARKLONE[installDir]}/src/systemd/scripts/functions/newPathUnit.sh"

newPathUnit "retroarch-saves" "/home/user/.config/retroarch/saves" "retroarch/saves" "retroarch-savefile"
```

### Create Path Units from a Directory ###

Multiple path units can be made from a directory and a specified depth of subdirectories with [newPathUnitsFromDir](systemd/scripts/functions/newPathUnitsFromDir.sh).

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t newPathUnitsFromDir)" = "function" ]] || source "${ARKLONE[installDir]}/src/systemd/scripts/functions/newPathUnitsFromDir.sh"

newPathUnitsFromDir "/path/to/roms" "retroarch/roms" 1 true "retroarch-savefile|retroarch-savestate" "/path/to/list-of-dirs-to.ignore"
```

`.ignore` files are simple line-delimited lists of patterns to check against the name of the subdirectory, and should be placed in [systemd/scripts/ignores](systemd/scripts/ignores). A [global ignore list](systemd/scripts/ignores/global.ignore) is also used to check subdirectories against, and contains unwanted items like `.DS_Store`, `.Trashes`, etc.

&nbsp;

---

## Wrapper to Kill a Script on Keypress ##

[killOnKeyPress](functions/killOnKeyPress.sh) runs a command and allows the user to kill the process by pressing any key. Along with [oga_controls](#wrapper-to-accept-gamepad-input-for-interactive-programs), this is useful for letting the user quit a process when their only connected input device is a gamepad.

```shell
#!/bin/bash
source "/opt/arklone/src/config.sh"
source "${ARKLONE[installDir]}/src/functions/killOnKeyPress.sh"

killOnKeyPress "/path/to/my/script.sh"
```

&nbsp;

---

## Wrapper to Accept Gamepad Input for Interactive Programs ##

[oga_controls](/vendor/oga_controls) ([source](https://github.com/christianhaitian/oga_controls)) converts gamepad input to key codes and mouse input data. [A wrapper script](/dialogs/input-listener.sh) is provided to automatically detect the input device and execute a command passed to it.

```shell
/opt/arklone/src/dialogs/input-listener.sh "/path/to/my/script.sh"
```

&nbsp;

---

## Logging ##

By default, arklone logs to the RAM filesystem at `/dev/shm/arklone.log`. This path can be set by the user and is available at `${ARKLONE[log]}`.

To use arklone's logger, run [arkloneLogger](functions/arkloneLogger.sh). All stdout/stderr will be logged to the log file until the process that called `arkloneLogger` quits.

```shell
#!/bin/bash
[[ ${#ARKLONE[@]} -gt 0 ]] || source "/opt/arklone/src/config.sh"
[[ "$(type -t arkloneLogger)" = "function" ]] || source "${ARKLONE[installDir]}/src/functions/arkloneLogger.sh"

arkloneLogger "${ARKLONE[log]}"

echo "Hello, world!"
```

&nbsp;

---

## Dialogs ##

[Dialogs](/dialogs) use `whiptail` and should be limited to acting as "views" whenever possible. Any non-trivial operations should be contained to functions or standalone scripts when possible.

```shell
#!/bin/bash
# Ask user if they want to say hello
function sayHelloScreen() {
	whiptail \
		--title "${ARKLONE[whiptailTitle]}" \
		--yesno \
			"Would you like to say hello?" \
			16 56 8
}

# Say hello
function sayHello() {
	echo "Hello, world!"
}

# Run the program
sayHelloScreen()

if [[ $? = 0 ]]; then
	sayHello
fi
```

&nbsp;

---

## Dirty Boot State ##

After boot, but before EmulationStation starts, arklone checks for a network connection and attempts to receive any new updates from the configured remote. It does not send any data until a file has been written on the device. This ensures that the cloud copy is the canonical and "always correct" one. 

If this process fails at any point, the dirtyboot state is set. Automatic syncing is disabled for the rest of the session, and the user will be warned about potential data loss on the following boot.

To manually reset the dirtyboot state, delete the lock file located at:
`~/.config/arklone/.dirtyboot`

For scripting, the path to `.dirtyboot` is available in `${ARKLONE[dirtyBoot]}`.

&nbsp;

---

## Other ##

Please refer to the inline documentation for other useful functions and scripts.

