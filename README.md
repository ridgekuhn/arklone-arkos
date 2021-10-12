# arklone #

rclone cloud sync utility for ArkOS

Watches save directories for RetroArch, and select standalone games.

This project offers no warranties or guarantees. Always make extra backup copies of your data. Use at your own risk!

arklone is released under a GNU GPLv3 license. See [LICENSE.md](/LICENSE.md) for more information.

rclone, RetroArch, EmulationStation, and ArkOS are the properties of their respective owners.

---

**Table of Contents**

1. [Installation](#installation)
2. [rclone Configuration](#configuration)
3. [First Run](#first-run)
4. [Settings Dialog](#settings-dialog)
5. [Syncing with the Cloud](#syncing-with-the-cloud)
6. [Advanced RetroArch Configuration](#settings-dialog)
7. [Recommended RetroArch Configuration](#known-bugs)
8. [Advanced arklone Configuration](#advanced-arklone-configuration)
9. [Troubleshooting](#troubleshooting)
10. [Developers](/DEVELOPERS.md)
11. [FAQ](#FAQ)



---

## Installation ##

This module is not yet integrated into ArkOS. See [this pull request](https://github.com/christianhaitian/arkos/pull/126) for updates.

To test, install manually by downloading the [installation script](https://github.com/ridgekuhn/arkos/raw/cloudbackups/10092021/install.sh), and run it from a terminal:

```shell
wget https://github.com/ridgekuhn/arkos/raw/cloudbackups/10092021/install.sh -O installArklone.sh
chmod a+x installArklone.sh
./installArklone.sh
rm ./installArklone.sh
```


### Uninstallation ###

```shell
wget https://github.com/ridgekuhn/arkos/raw/cloudbackups/10092021/uninstall.sh -O uninstallArklone.sh
chmod a+x uninstallArklone.sh
./uninstallArklone.sh
rm ./uninstallArklone.sh
```



---

## rclone Configuration ##

To begin using arklone, you must create an rclone config file. For [most cloud providers](https://rclone.org/remote_setup/), this will involve installing `rclone` to a computer with a web browser, like your desktop or laptop. See the [rclone docs](https://rclone.org/docs/#configure) for more information on how to do this for your specific provider. Make sure you [install the latest version of rclone](https://rclone.org/downloads/), (1.56.2 when this was written). *If you use a package manager like `apt`, the repository version will be outdated.*

Once you have completed this process, copy the `rclone.conf` file from your computer to your ArkOS device. Your `rclone.conf` can be located by running:

```
rclone config file
```


On your ArkOS SD card, copy `rclone.conf` to:
`EASYROMS/backup/rclone/rclone.conf` 

If you already had rclone installed on your device, your `rclone.conf` has been moved to EASYROMS for easier access, and symlinked to its original location. arklone will restore the original arrangement if uninstalled.



---

## First Run ##

From EmulationStation, navigate to Options -> Cloud Settings

On first run, you will be greeted by a prompt asking if you'd like to change your RetroArch configurations to the recommended settings.

Obviously, this is recommended!

This will set the following settings in your retroarch.cfg (and your retroarch32/retroarch.cfg):

```
savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "false"
sort_savefiles_enable = "false"
sort_savefiles_by_content_enable = "true"

savestate_directory = "~/.config/retroarch/saves"
savestates_in_content_dir = "false"
sort_savestates_enable = "false"
sort_savestates_by_content_enable = "true"
```


This will result in savefiles and savestates being stored in the same directory hierarchy as your RetroArch content root, in `~/.config/retroarch/saves`

eg,
`~/.config/retroarch/saves/nes/TheLegendOfZelda.srm`
`~/.config/retroarch/saves/nes/TheLegendOfZelda.savestate0`

![First run screen](/.github/arklone1.png)


### Settings Dialog ###

* **Set cloud service**
		Allows you to select from the remotes you set up in `rclone.conf`
* **Manually sync saves**
		Manually sync a single directory.
* **Enable/Disable automatic saves sync**
		Watches directories for changes and syncs them to your selected remote.
* **Manual backup/sync ArkOS settings**
		Runs the ArkOS backup script and uploads the file to the selected remote.
* **Regenerate RetroArch path units**
		Re-scans for new RetroArch directories to watch and generates path units for them.
* **View log file**
		Shows the log file.

![Arklone main menu](/.github/arklone2.png)



---

## Syncing with the Cloud #

Keeping multiple devices synced can be difficult. arklone tries to do its best, but you should always keep an extra backup copy just in case.

### Automatic Syncing ###

If you enable automatic syncing in the settings dialog, arklone assumes the copy of your data stored in the cloud is the canonical and "always correct" version. On system boot, arklone will run before EmulationStation and attempt to receive updates from the cloud remote. *If the remote contains a newer version of a file, it will overwrite the local copy.* On this initial sync, *arklone only receives updates and does not send anything back*. If this process fails for any reason, the user is notified, and the [dirty boot state](#dirty-boot-state) is set.

If the boot sync process succeeds, arklone then assumes your local device contains the correct copy for the rest of the session, and will *send updates first, overwriting older copies on the remote, before receiving new content*.


## Manual Syncing ###

If you do not enable automatic syncing, arklone assumes the data on your device is the "always correct" version. Manually syncing a directory from the settings dialog will always *send updates first, overwriting older copies on the remote, before receiving new content*. Be careful, as this can lead to data loss when doing this with multiple devices.



---

### Dirty Boot State ###

After boot, but before EmulationStation starts, arklone checks for a network connection and attempts to receive any new updates from the configured remote. It does not send any data back until a file has been written on the device. This ensures that the cloud copy is the canonical and "always correct" one. 

If this process fails at any point, the dirtyboot state is set. Automatic syncing is disabled for the rest of the session, and the user will be warned about potential data loss on the following boot.

To manually reset the dirtyboot state, delete the lock file located at:
`~/.config/arklone/.dirtyboot`



---

## Advanced RetroArch Configuration ##

This section is for users who wish to have more control over their retroarch.cfg settings and save directories.


### Supported RetroArch Configuration ###

ArkOS includes 64-bit and 32-bit builds of RetroArch.
The configuration files are stored at
`/home/ark/.config/retroarch/retroarch.cfg` and
`/home/ark/.config/retroarch32/retroarch.cfg`.

The following settings are supported:

```
savefile_directory
savefiles_in_content_dir
sort_savefiles_enable
sort_savefiles_by_content_enable

savestate_directory
savestates_in_content_dir
sort_savestates_enable
sort_savestates_by_content_enable
```


For the next examples, `filetype` refers to either `savefile` or `savestate`.

If `filetypes_in_content_dir = "true"`, it will override the other related settings, and create save data next to the content file.

Otherwise, if `sort_filetypes_enable = "true"`, save data will be organized by libretro core inside `filetype_directory`.
eg,
`/path/to/filetype_directory/FCEUmm/TheLegendOfZelda.srm`

If `sort_filetypes_by_content_enable = "true"`, save data will be organized by the parent directory of the content file.
eg,
`/path/to/filetype_directory/nes/TheLegendOfZelda.srm`

If both `sort_filetypes_enable = "true"` and `sort_filetypes_by_content_enable = "true"`, save data will be organized by the parent directory of the content file, then by libretro core.
eg,
`/path/to/filetype_directory/nes/FCEUmm/TheLegendOfZelda.srm`


### Known Bugs ###

ArkOS currently contains a bug which prevents systemd path units from watching subdirectories of exFAT partitions. (See [issue #289](https://github.com/christianhaitian/arkos/issues/289).) This means that savefiles/savestates can not be watched (and automatically synced) if `filetypes_in_content_dir = "true"`.

Until this bug is resolved, if you wish to store your saves next to the content, you must manually sync your saves from the arklone dialog.

Since the bug only applies to exFAT partitions, advanced users who really want to use automatic syncing and keep savefiles/savestates in the content directories can re-format the EASYROMS partition to FAT32, ext4, etc and edit the mount entry in `/etc/fstab`.


### Recommended RetroArch Configuration ###

```
savefile_directory = "~/.config/retroarch/saves"
savefiles_in_content_dir = "false"
sort_savefiles_enable = "false"
sort_savefiles_by_content_enable = "true"

savestate_directory = "~/.config/retroarch/states"
savestates_in_content_dir = "false"
sort_savestates_enable = "false"
sort_savestates_by_content_enable = "true"
```



---

## Advanced arklone Configuration ##

Arklone has a few settings that can be changed by the user, mostly paths where arklone looks for various files. The user configuration file is stored at `~/.config/arklone/arklone.cfg`.


### Resetting to "First Run" State ###

Setting `remote` to an empty string forces the settings dialog to show the "first run" screen again.

**arklone.cfg**

```
remote = ""
```


### Changing RetroArch Content Root ###

Where `filetype` refers to either `savefile` or `savestate`:

If your `retroarch.cfg` contains the settings `filetypes_in_content_dir = "true"` or `sort_filetypes_by_content_enable = "true"`, arklone expects your RetroArch content to be organized in a directory hierarchy with one level of subdirectories, where each contains all content for a particular platform.
eg,
`retroarchContentRoot/nes/TheLegendOfZelda.rom`

**arklone.cfg**

```
retroarchContentRoot = "/absolute/path/to/retroarchContentRoot"
```


arklone also supports select standalone software and "ports". See the [systemd/units](/systemd/units) for a list, and the [Path Units](/DEVELOPERS.md#path-units) section of the developer docs for more info.


### Multiple RetroArch Instances ###

arklone supports multiple instances of RetroArch, in case your distro has both 64-bit and 32-bit builds installed. Set `retroarchCfg` to a space-delimited list of absolute paths to each `retroarch.cfg`.

**arklone.cfg**

```
retroarchCfg = "/home/user/.config/retroarch/retroarch.cfg /home/user/.config/retroarch32/retroarch.cfg"
```


### rclone Filters ###

arklone passes various filter lists to `rclone` when a sync script is run. See the [Path Units](/DEVELOPERS.md#path-units) and [rclone Filters](/DEVELOPERS.md#rclone-filters) sections of the developer docs for more info.



---

## Troubleshooting ##

### RetroArch Saves Not Syncing ###

arklone only watches the RetroArch save directories it knew about when it first generated the corresponding path units. If you selected "Set Recommended Settings" on your first run, arklone will automatically generate path units for all your RetroArch content directories which are not empty. If you've added games since then and some of your save directories are not being synced automatically, try manually regenerating them from the arklone dialog menu.

If you change any of the above settings in `retroarch.cfg`, you must also manually regenerate the path units.


### Ports, Standalone Apps, or Other Game Saves Not Syncing ###

ArkOS is constantly updated with new apps and ports, and we probably haven't caught up to them yet. Please [create a new issue](https://github.com/ridgekuhn/arklone-arkos/issues) so we can include it in a future update.


### Logging ###

To save unnecessary writes to your SD card or hard drive, arklone writes logs to the RAM filesystem at `/dev/shm/arklone.log`. This file disappears when the system is powered down, but you can view it by opening the arklone settings dialog and selecting "View log file".



---

## Developers ##

Contributions are welcome! Please see the [developer docs](/DEVELOPERS.md).



---

## FAQ ##

#### Can I use it on Windows, MacOS, or other Linux Distros? ####

**Linux**

A RetroPie release is planned soon. arklone is written in bash, and relies on tools like `apt`, `dpkg`, and `inotify-tools`. It should theoretically work on any Debian-based distro, as long as your content is organized in the [expected directory hierarchy](#changing-retroarch-content-root). See [Advanced arklone Configuration](#advanced-arklone-configuration) for more info.

**Windows and MacOS**

If your cloud provider offers a desktop client, you should install and use that instead.


#### Can I add my own custom directories? ####

See the [Path Units](/DEVELOPERS.md#path-units) section of the developer docs.


#### Why Am I Seeing "ERROR: Directory Not Found" During Boot?  ####

If you have automatic syncing enabled, arklone attempts to download all the different save directories it knows about from the cloud remote. If they don't exist on the cloud remote, these messages are generated for logging and debugging purposes. If there are any actual problems downloading save data from the cloud, you will be presented with a dialog screen, and asked if you want to proceed or view the log file. If you don't see this dialog screen and your device boots straight into EmulationStation, then everything is ok!


#### Can I Use arklone to Sync ROMs or BIOS files? ####

Not unless you want to [set it up yourself](/DEVELOPERS.md). Many users' game libraries are massive and would probably exceed the storage limit on your cloud account several times over. There are also system performance implications for keeping this much data synced on low-power devices, like the ones ArkOS is designed for, where the background sync operations may affect gameplay. It's probably much faster/efficient to transfer your game libraries from device-to-device via USB or over your LAN.

