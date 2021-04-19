# The Vimac Manual

## Workflow

The current Vimac workflow works like this:

1. Activate a mode
2. Perform actions within the activated mode
3. Exit the mode, either manually or automatically when the mode's task is complete

## Modes

There are two modes in Vimac.

### Hint-mode

Activating Hint-mode allows one to perform a click, double-click, or right-click on an actionable UI element

Upon activation (default shortcut is `Control-F`), "hints" will be generated for each actionable element on the frontmost window:

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

## Activation

There are two ways to activate modes:

- Keyboard Shortcut (e.g. `Control-F`)
- Key Sequence (e.g. `fd`)
  - Must be at least two characters long
  - Is not a prefix of another registered key sequence

You may configure the bindings in the Bindings tab in Preferences:

<img src="bindings.png">