# arklone #
rclone cloud syncing for ArkOS

---

## Installation ##
This module is not yet integrated into ArkOS. See [this pull request](https://github.com/christianhaitian/arkos/pull/126) for updates.

To test and install manually,
download the installation script, and run it from a terminal:

```shell
cd ~
wget https://raw.githubusercontent.com/ridgekuhn/arkos/cloudbackups/arklone20210118/install.sh -O installArklone.sh
chmod a+x installArklone.sh
./installArklone.sh
```

This will also install the [joy2key](https://github.com/ridgekuhn/joy2key) library.

## Uninstallation ##
The uninstall script will remove everything except for rclone (in case the user already had it installed).

```shell
cd ~
wget https://raw.githubusercontent.com/ridgekuhn/arkos/cloudbackups/arklone20210118/uninstall.sh -O uninstallArklone.sh
chmod a+x uninstallArklone.sh
./uninstallArklone.sh
```

### Configure rclone.conf ###
Your `rclone.conf` file is stored on the EASYROMS partition at:
`backup/rclone/rclone.conf` 

See the [rclone docs](https://rclone.org/docs/) for instructions on how to
configure your `rclone.conf` file for supported cloud providers.
For most cloud providers, you will need access to a desktop computer
with rclone, and a web browser to generate your API keys.
`rclone` will generate the `rclone.conf` file for you at the end of the process,
then you can simply copy the generated file from your desktop computer
to the EASYROMS partition of your microSD card.

If you don't wish to install rclone on your desktop computer,
Dropbox is the only cloud provider we've tested which doesn't require the use
of rclone to get the needed API keys, so we will use Dropbox for
the following tutorial:

1. Log in to your Dropbox account.

2. Visit [https://www.dropbox.com/developers/apps](https://www.dropbox.com/developers/apps)
		and click on the "App Console" button.
![Go to app console](/.github/dropbox2.png)


3. Click on the "Create App" button.
![Create app](/.github/dropbox3.png)


4. Select "Scoped access", "App folder", and give your new app a name.
		Dropbox will create a folder named "Apps" at the root directory
		of your Dropbox account, and whatever you choose here will be
		a subdirectory inside of the Apps folder.
![Dropbox app setup](/.github/dropbox4.png)


5. Click on the "Permissions" tab.
		Assign all read/write permissions to your app.
![Set app permissions](/.github/dropbox5.png)


6. Click on the "Settings" tab, and scroll down.
![Set app general settings](/.github/dropbox6.png)


7. Under "Access token expiration", select "No expiration".
		Under "Generated access token", click the "Generate" button.
![Generate access token](/.github/dropbox7.png)


8. Copy "App key", "App secret", and "Generated access token"
		to your `rclone.conf` file.
![Get app key, secret, and token](/.github/dropbox8.png)


Your `rlone.conf` file should look like this:
```
[dropbox]
type = dropbox
client_id = YOUR_APP_KEY
client_secret = YOUR_APP_SECRET
token = {"access_token":"YOUR_ACCESS_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}
```

## Run it! ##
In EmulationStation, navigate to Options -> Cloud Settings

### First Run ###
On first run, you will be greeted by a prompt asking if you'd like to change
your RetroArch configurations to the recommended settings.
Obviously, this is recommended!

![First run screen](/.github/arklone1.png)

### Main Menu ###
* **Set cloud service**
		Allows you to select from the cloud providers you set up in `rclone.conf`
* **Manually sync savefiles/savestates**
		Allows you to manually sync a single directory for which a path unit exists.
* **Enable/Disable automatic saves sync**
		Watches directories for changes if a path unit exists,
		and syncs the directory to the cloud
* **Manual backup/sync ArkOS settings**
		Runs the ArkOS backup script and uploads the file to the cloud
* **Regenerate RetroArch path units**
		Re-scans for new directories to watch and generates path units for them.

![Arklone main menu](/.github/arklone2.png)

## Advanced Configuration ##
This section is for users who wish to have more control
over their retroarch.cfg settings and save directories.

### Supported Settings ###
ArkOS includes 64-bit and 32-bit builds of RetroArch.
The configuration files are stored at
`/home/ark/.config/retroarch/retroarch.cfg` and
`/home/ark/.config/retroarch32/retroarch.cfg`.

The following settings are supported:
```
savefile_directory
savefiles_in_content_dir
sort_savefiles_enable

savestate_directory
savestates_in_content_dir
sort_savestates_enable
```

### Unsupported Settings ###
The following settings are implemented differently depending on which
build of RetroArch you are using,
and are unsupported so we can ensure compatibility with all platforms.

_Both settings must be set to_ `"false"`:
```
sort_savefiles_by_content_enable
sort_savestates_by_content_enable
```

### Known Bugs ###
ArkOS currently contains a bug which prevents systemd path units
from watching subdirectories of exFAT partitions. (See [issue #289](https://github.com/christianhaitian/arkos/issues/289).)

This means that savefiles/savestates can not be watched
and automatically synced if they are stored
in the content directories (on EASYROMS, eg `/EASYROMS/nes`),
via the `savefiles_in_content_dir` and `savestates_in_content_dir` settings.

Until this bug is resolved, if you wish to store your saves on EASYROMS,
you must manually sync your saves from the arklone dialog.

Since the bug only applies to exFAT partitions,
advanced users who really want to use automatic syncing
and keep savefiles/savestates in the content directories
can re-format the EASYROMS partition
to FAT32, ext4, etc and edit the mount entry in `/etc/fstab`.

### Recommended Settings ###
```
savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "false"
sort_savefiles_enable = "false"
sort_savefiles_by_content_enable = "false"

savestate_directory = "~/.config/retroarch/states"
savestates_in_content_dir = "false"
sort_savestates_enable = "false"
sort_savestates_by_content_enable = "false"
```

### Example Settings ###
We use `savefile` for the following examples,
but the same applies for `savestate`:
```
savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "true"
sort_savefiles_enable = "false"
// Save directory: ${CONTENT_DIR}/${system}

savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "true"
sort_savefiles_enable = "false"
// Save directory: ${CONTENT_DIR}/${system}

savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "true"
sort_savefiles_enable = "true"
// Save directory: ${CONTENT_DIR}/${system}

savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "false"
sort_savefiles_enable = "false"
// Save directory: ${savefile_directory}

savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "false"
sort_savefiles_enable = "false"
// Save directory: ${savefile_directory}/${libRetroCore}
```

#### Troubleshooting ####
Watchers are created for directories
based on your `retroarch.cfg` settings above.

If you have `sort_savefiles_enable` or `sort_savestates_enable` set to `"true"`,
some of the directories may not be created until you have launched the related
content from RetroArch. If some of your save directories
are not being synced automatically,
try manually regenerating them from the arklone dialog menu.

If you change any of the above settings in `retroarch.cfg`,
you must also manually regenerate the path units.

---

## Developers ##
This module contains four main parts:
* A systemd service template for monitoring instance directories
* A standalone script which syncs the ArkOS settings backup to the cloud
* A standalone script which syncs two directories using rclone
* A whiptail frontend for the scripts and services above

### [systemd units](/systemd/units) ###
To watch a directory, create a new file at `/opt/arkloned/systemd/units/arkloned-${myPathUnit}.path`. Only 3 lines are needed:

```shell
[Path]
PathChanged=/path/to/watch
Unit=arkloned@-path-to-watch\x40path-to-sync-to\x40filter
```

The `Unit=` value must be in the format:
`arkloned@${escapedString}`, where the escaped string is in the format:
`${localDir}@${remoteDir}@${filter}`

`${filter}` refers to a .filter file in `arklone/rclone/filters`
The filter is optional, but the string must containing the preceding `@`.

Do not use trailing slashes for either path.
The remote directory must also not have an opening slash.

You can generate an escaped string using the `systemd-escape` tool:

```shell
$ systemd-escape "/path/to/watch@path/to/sync/to@myFilter"
# outputs:
# -path-to-watch\x40path-to-sync-to\x40myFilter
```

[settings.sh](/dialogs/settings.sh) will automatically handle enabling
and starting the path unit when the user enables automatic syncing.

#### Generating systemd RetroArch Units ####
Retroarch path units are generated automatically by [generate-retroarch-units.sh](/systemd/scripts/generate-retroarch-units.sh)

The script supports multiple instances of RetroArch,
and all permutations of the following settings in retroarch.cfg:
```
`savefile_directory`
`savefiles_in_content_dir`
`sort_savefiles_enable`

`savestate_directory`
`savestates_in_content_dir`
`sort_savestates_enable`
```

The following settings are implemented inconsistently
between builds of RetroArch, and are unsupported by this script.
If the script detects the value of these settings as "true",
it will exit with code 73.
```
sort_savefiles_by_content_enable
sort_savestates_by_content_enable
```

### [arklone-saves.sh](/rclone/script/arklone-saves.sh) ###
Syncs two directories using rclone

Called by:
* [arkloned@.service template](/systemd/units/arkloned@.service) when a corresponding _arkloned-*.path_ unit is started.
* [settings.sh](/dialogs/settings.sh)

To execute manually, pass two directories and a filter
as a string to the first argument, in the format `localDir@remoteDir@filter`.

`filter` refers to a .filter file in `arklone/rclone/filters`

_Do not use trailing slashes. The remote directory also must not have an opening slash._

```shell
$ /opt/arklone/arklone.sh "/roms@retroarch/roms@retroarch-savefiles"

```

### [arklone-arkos.sh](/rclone/script/arklone-arkos.sh) ###
Calls the ArkOS backup script and syncs the resulting file to the cloud.

Called by:
* [settings.sh](/dialogs/settings.sh)

### [settings.sh](/dialogs/settings.sh) ###
A whiptail dialog menu which allows the user to execute the above scripts.

The script is loosely divided into an MVC pattern,
where whiptail dialogs are "view" functions and the script functionality
lives in separate "controller" functions.

The main views are:
* Set cloud service
* Manual sync savefiles/savestates
* Enable/Disable automatic syncing
* Regenerate RetroArch path units
* Manual sync ArkOS Settings
