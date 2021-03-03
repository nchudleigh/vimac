# Supporting non-native applications

Vimac depends on the target application's Accessibility support to find clickable hints.

Chromium and Firefox and other non-native applications do not enable Accessibility by default for performance reasons. You need a way to tell them to enable accessibility, and preferably not keep it on all the time. Ideally, you would only enable it right before querying for elements.

Examples of non-native applications:

- Chrome
- Firefox
- VSCode

## Vimac does not support a non-native application I'm using. What should I do?

1. Is there an option to manually enable accessibility features on the application?

    - e.g. Chrome allows manually enabling Accessibility in `chrome://accessibility`. See http://www.chromium.org/developers/design-documents/accessibility

2. Can I modify the application to allow enabling accessibility through `AXManualAccessibility`?

    - Refer to [Electron support with AXManualAccessibility](#electron-support) and [Help Needed: Extending browsers to support AXManualAccessibility](#help-needed)


## Emulating VoiceOver with AXEnhancedUserInterface

The `AXEnhancedUserInterface` attribute is used by VoiceOver to tell applications that VoiceOver is enabled. Chromium and many other non-native applications waits for this to be set to true before enabling their Accessibility features. See https://www.chromium.org/developers/design-documents/accessibility.

A side-effect of `AXEnhancedUserInterface` attribute is that it breaks window positioning with window managers like Magnet. Hence, I have opted not to support `AXEnhancedUserInterface`.

## Electron support with AXManualAccessibility

The people working on Electron realised the need for enabling Accessibility on Electron-built applications without dealing with the previously mentioned broken window positioning bug.

Electron allows you to enable accessibility through the `AXManualAccessibility` attribute. See https://www.electronjs.org/docs/tutorial/accessibility#macos. Vimac currently sets this attribute to true on frontmost windows.

Note that this might result in slower performance in Electron applications. As a workaround, I plan on adding the ability to blacklist applications from this attribute.

## Help Needed: Extending browsers to support AXManualAccessibility

Vimac's usefulness would be greatly increased if it supported non-native browsers like Chrome. I believe that those browsers (and other non-native applications) should follow Electron and support the enabling/disabling of accessibility through the `AXManualAccessibility` attribute.

I have filed 

Of course, ideally `AXEnhanceUserInterface` shouldn't be breaking window positioning, but this problem has been present for so long I'm not optimistic Apple will fix it.

