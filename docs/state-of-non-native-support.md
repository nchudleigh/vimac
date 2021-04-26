# State of Chromium and Electron Support (22 April 2021)

TLDR:

1. Chrome and Brave now work with non-native support disabled. Firefox does not.
2. Keep Electron Support enabled until Electron 12 is released and all your Electron apps are on Electron 12. Ask developers of Electron apps to update their Electron versions to v12 so that it is compatible with Voice Control and Vimac.
3. Only enable Non-native Support / VoiceOver emulation if you really need it for Firefox or CEF apps (Spotify). I recommend reaching out to them asking for Voice Control support.

As of v0.3.18, Vimac is able to support Chromium and Electron apps by providing two options in the Experimental tab:

1. Non-native Support (AXEnhancedUserInterface)
2. Electron Support (AXManualAccessibility)

There are two problems with the current approaches:

1. Emulating VoiceOver has weird side effects
  - Breaks window managers like Spectacle
  - https://github.com/dexterleng/vimac/issues/382
  - https://github.com/dexterleng/vimac/issues/351
2. Performance hit.
  - Both VoiceOver and AXManualAccessibility cause Chromium to set up more Accessibility stuff than needed than Vimac or Voice Control.
Chromium has different levels of accessibility. See [2]’s description.

A Chromium patch submitted on Feb 13, 2021 [2] changes the way Chromium detects the presence of Voice Control. Basic Accessibility is enabled after reading the “role” attribute from any Chrome accessibility element.

**Implications**: You do not have to enable Non-native Support or Electron Support for Chromium/Electron apps with this patch. Electron 12 has this patch applied.

I’m currently running the latest stable Chrome version (90.0.4430.85) and can confirm that Hint-mode works without enabling the Non-native Support option.

However, it appears several popular non-native apps have not applied this patch:

1. Electron apps pre v12 (VSCode, Slack...)
2. Firefox
4. Spotify (1.1.57.443.ga029a6c4)

I’ll request for them to update their Chromium/Electron versions since both Voice Control and Vimac (with both non-native options disabled) do not work on those apps.

## Changes on my end

Going forward, as more non-native apps update their Chromium/Electron versions, there will be less of a need for these two Experimental options.

When Electron 12 gains more adoption, I’ll update the descriptions of the Electron option to state that these are for legacy Electron apps.

Meanwhile (for v0.3.18), since the latest stable version of Chrome already works without enabling Non-native support, I will update the description of the Non-native support option to discourage enabling it.

[1] https://www.electronjs.org/docs/tutorial/accessibility

[2] Enable basic accessibility when “role” is read
https://chromium-review.googlesource.com/c/chromium/src/+/2680102

