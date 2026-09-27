# minui-screenshot-monitor.pak

A MinUI app allowing for taking screenshots on the device using a hotkey.

## Requirements

This pak is designed and tested on the following MinUI Platforms and devices:

- `h700`: Anbernic RG28XX, RG34XX, RG34XX SP, RG35XX Plus, RG35XX 2024, RG35XX H, RG35XX Pro, RG35XX SP, RG40XX H, RG40XX V, RG CubeXX and RG SP, running NextUI on BaseOS
- `miyoomini`: Miyoo Mini Plus and the Miyoo Mini
- `my282`: Miyoo A30
- `my355`: Miyoo Flip
- `rg35xxplus`: RG-35XX Plus, RG-34XX, RG-35XX H, RG-35XX SP
- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro
- `tg5050`: Trimui Smart Pro S

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

Press the hotkey when in game. A png screenshot will appear on the SDCard, in `/mnt/SDCARD/Screenshots`, with the name of the game and the current date as the filename. Characters that cannot be stored on the SD card are replaced in the filename: `:` becomes ` - ` and `\ / * ? " < > |` become `_`.

### hotkey

> [!IMPORTANT]
> If one of the hotkeys in use is mapped to something else within MinUI, the pak may not trigger.

The default hotkey is `btn_l2` - see the Input app to determine what this maps to on your device. To utilize a different hotkey, create a file named `hotkey` in the `$SDCARD_PATH/.userdata/$PLATFORM/Screenshot Monitor` folder with the name of the key you want to monitor. Any of the [buttons supported by `minui-btntest`](https://github.com/josegonzalez/minui-btntest#buttons) are supported, except `btn_none`. Names are case-insensitive and the `btn_` prefix is optional, so `L2`, `l2`, and `btn_l2` are all equivalent. You can also specify multiple by using a comma-separated list (e.g. `btn_l1,btn_r1`), in which case all of the buttons must be held at the same time.

Holding the hotkey takes a single screenshot. Release and press it again to take another.

If the hotkey file contains an invalid button, the screenshot monitor will not start and an `Invalid hotkey` message is shown.

### Debug Logging

Debug logs are written to the`$SDCARD_PATH/.userdata/$PLATFORM/logs/` folder.

## Development

Run `make test` to run the test suite. The tests require [`bats`](https://github.com/bats-core/bats-core).
