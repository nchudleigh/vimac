# The Vimac Manual

## Workflow

The current Vimac workflow works like this:

1. Activate a mode (see [Activation Mechanisms](#activation-mechanisms))
2. Perform actions within the activated mode
3. Exit the mode, either manually or automatically when the mode's task is complete

## Modes

There are two modes in Vimac.

### Hint-mode

Activating Hint-mode allows one to perform a click, double-click, or right-click on an actionable UI element

Upon activation, "hints" will be generated for each actionable element on the frontmost window:

<img src="hint-mode.gif">

Simply type the assigned "hint-text" (eg. "sa") to perform a click at the location!

| Action      | How to trigger |
|-----------|-------------
| Left click | Type the assigned hint-text |
| Right click | Type the assigned hint-text while holding `Shift` |
| Double left click | Type the assigned hint-text while holding `Command` |
| Move cursor | Type the assigned hint-text while holding `Option` |
| Rotate hints | `Space` |
| Exit | `Escape` or `Control + [`|

Tip(s):
- After executing a right-click action, use `Control-N` and `Control-P` to select the next and previous context menu item respectively.

### Scroll-mode

Activating Scroll-mode allows one to scroll through the scrollable areas of the frontmost window.

Upon activation (default shortcut is `Control-J`), a red border surrounds the active scroll area:

<img src="scroll-mode.gif">

HJKL keys can be used to scroll within the scroll area.

| Action      | Default Key |
|-----------|-------------
| Scroll down | j |
| Scroll up | k |
| Scroll left | h |
| Scroll right | l |
| Scroll down by half the height of the scroll area | d |
| Scroll up by half the height of the scroll area | u |
| Scroll to top of page | gg |
| Scroll to bottom of page | G |
| Activate another scroll area | `Tab` |
| Exit | `Escape` or `Control + [`|

You can also scroll up/down/left/right by half a page by holding `Shift` when pressing the `hjkl` keys.

## Activation Mechanisms

Vimac allows you to perform mouse actions with the keyboard. You'll want to make activating modes as easy and convenient as possible.

There are three ways to activate modes:

1. Hold `Space` to activate Hint-mode (Recommended)
2. Keyboard Shortcut (e.g. `Control-F`)
3. Key Sequence (e.g. `fd`)
  - Must be at least two characters long
  - Is not a prefix of another registered key sequence
  - If you are a Vimium user, consider using `;f` and `;a` so it does not add delays or interfere with Vimium's bindings

You may configure the bindings in the Bindings tab in Preferences.

If these activation mechanisms do not fit your use case, do look into creating custom bindings with Karabiner Elements. Please share with me your custom activation mechanisms! This is an area I spend a lot of time thinking about and improving.

Some custom bindings I've tried or seen others trying:

1. Caps-Lock + F/J. Caps-Lock can be mapped to a Hyper key or CTRL key with Karabiner
2. Thumb key to activate Hint-mode. Some ergonomic keyboards have thumb keys that can be mapped to Vimac shortcuts.

## Chrome/Firefox/VSCode/Non-native Support

Refer to [State of Non-native Support](./state-of-non-native-support.md).

TLDR:

1. Browser Support: Safari, Chrome, and Brave works by default. You need to enable `Non-native Support` for Firefox to work.
2. Pre Electron v12 apps need `Electron Support` enabled to work.
3. Only enable `Non-native Support` / `VoiceOver Emulation` if you really need it for Firefox or CEF apps (Spotify). I recommend reaching out to them asking for Voice Control support.