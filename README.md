# Vimac

Vimium for macOS.

## Download

You can find releases in [dexterleng/vimac-releases](https://github.com/dexterleng/vimac-releases).

You can find the download link for v0.3.7 [here](https://github.com/dexterleng/vimac-releases/raw/master/vimac-v0.3.7.zip).

## Installing

Note that Mojave is the minimum version supported right now. Catalina has not been tested. You will need to give Vimac **Accessibility** permissions in **Security & Privacy.**

:warning: **When you update Vimac, even though the app is in the permissions list, you have to untick and tick it (or remove and add back) for permissions to be granted.**

## How to use Vimac

**Hint Mode (CTRL+SPACE)** \
Once Hint Mode is activated you can typed the hint letters to perform a click.

**Right-Click** \
Hold SHIFT while typing the hint text.

**Double-Click** \
Hold CMD while typing the hint text. \
You can cycle between all hints and hints only for actionable elements with TAB.

**Scrolling (CTRL+S)** \
Scroll mode allows you to scroll with HJKL + DU keys. \
D and U scroll the page down and up respectively by half the height of the scroll area. \
You can cycle through the scroll areas with the TAB key.

## Tips

* When the yellow hints are shown on-screen, you can use the Spacebar to rotate the height of the overlapping hints.
* After executing a right-click command, use CTRL-N and CTRL-P to select the next and previous menu bar item respectively.

## Building

Add Vimac to the list of Accessibility apps under **System Preferences > Security & Privacy > Accessibility**.

Keep System Preferences open under this section during development with the settings unlocked. This is because the `grant-accessibility-permission-dev.scpt` AppleScript is scheduled to run after each build to re-grant Accessibility permissions.

The AppleScript simply checks and unchecks Vimac to re-grant permissions which are lost after a cleanbuild.

## Contributing

Feel free to contribute to Vimac. Make sure to open an issue / ask to work on something first!
