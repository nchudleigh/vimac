<div align="center">
  <h1>Vimac</h1>
  <p>Vimium for macOS.</p>
</div>

## Download

You can find releases in [dexterleng/vimac-releases](https://github.com/dexterleng/vimac-releases).

You can find the download link for v0.3.6 [here](https://github.com/dexterleng/vimac-releases/raw/master/vimac-v0.3.6.zip).

## Building

Add Vimac to the list of Accessibility apps under **System Preferences > Security & Privacy > Accessibility**.

Keep System Preferences open under this section during development with the settings unlocked. This is because the `grant-accessibility-permission-dev.scpt` AppleScript is scheduled to run after each build to re-grant Accessibility permissions.

The AppleScript simply checks and unchecks Vimac to re-grant permissions which are lost after a cleanbuild.

## Contributing

Feel free to contribute to Vimac. Make sure to open an issue / ask to work on something first!
