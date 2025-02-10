# minui-screenshot-monitor.pak

A MinUI app allowing for taking screenshots on the device using a hotkey.

## Requirements

This pak is designed and tested on the following MinUI Platforms and devices:

- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro
- `rg35xxplus`: RG-35XX Plus, RG-34XX, RG-35XX H, RG-35XX SP

Use the correct platform for your device.

## Installation

1. Mount your MinUI SD card.
2. Download the latest release from Github. It will be named `Screenshot.Monitor.pak.zip`.
3. Copy the zip file to `/Tools/$PLATFORM/Screenshot Monitor.pak.zip`. Please ensure the new zip file name is `Screenshot Monitor.pak.zip`, without a dot (`.`) between the words `Screenshot` and `Monitor`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Screenshot Monitor.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your MinUI device.

## Usage

> [!IMPORTANT]
> If the zip file was not extracted correctly, the pak may show up under `Tools > Screenshot`. Rename the folder to `Screenshot Monitor.pak` to fix this.

Browse to `Tools > Screenshot Monitor` and press `A` to turn on the screenshot monitor.

Press the hotkey when in game. A png screenshot will appear on the SDCard, in `/mnt/SDCARD/Screenshots`, with the name of the game and the current date as the filename.

### hotkey

> [!IMPORTANT]
> If one of the hotkeys in use is mapped to something else within MinUI, the pak may not trigger.

The default hotkey is `L2` - see the Input app to determine what this maps to on your device. To utilize a different hotkey, create a file named `hotkey` in the pak folder with the name of the key you want to monitor. Any of the buttons supported by [`minui-btntest`](https://github.com/josegonzalez/minui-btntest) are supported. You can also specify multiple by using a comma-separated list.

### Debug Logging

To enable debug logging, create a file named `debug` in the pak folder. Logs will be written to the `$SDCARD_PATH/.userdata/$PLATFORM/logs/` folder.
