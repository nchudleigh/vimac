//
//  StatusItemManager.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 19/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import Sparkle
import Preferences

class StatusItemManager: NSMenu, NSMenuDelegate, NSWindowDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let preferencesWindowController: PreferencesWindowController
    
    override init(title: String) {
        self.preferencesWindowController = PreferencesWindowController(
            preferencePanes: [
                GeneralPreferenceViewController(),
                BindingsPreferenceViewController(),
                HintModePreferenceViewController(),
                ScrollModePreferenceViewController(),
            ],
            style: .toolbarItems,
            animated: true
        )
        super.init(title: title)
        
        self.preferencesWindowController.window?.delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func awakeFromNib() {
        guard let button = statusItem.button else {
            return
        }
        button.image = NSImage(named: "StatusBarButtonImage")
        statusItem.menu = self
        statusItem.menu?.delegate = self
    }
    
    func menuWillOpen(_ _menu: NSMenu) {
        if let menu = statusItem.menu {
            menu.removeAllItems()
            menu.addItem(withTitle: "Preferences", action: #selector(preferencesClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Check for updates", action: #selector(checkForUpdatesClick), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit", action: #selector(quitClick), keyEquivalent: "").target = self
        }
    }
    
    @objc func preferencesClick() {
        preferencesWindowController.show()
    }
    
    @objc func checkForUpdatesClick() {
        SUUpdater.shared()?.checkForUpdates(nil)
    }
    
    @objc func quitClick() {
        NSApplication.shared.terminate(self)
    }
}

// Show Vimac in the Dock when Preferences are open, and revert back to hidden when closed
// Vimac starts in the background because of LSUIElement = true in Info.plist
extension StatusItemManager {
    func windowDidBecomeMain(_ notification: Notification) {
        let transformState = ProcessApplicationTransformState(kProcessTransformToForegroundApplication)
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, transformState)
    }
    
    func windowWillClose(_ notification: Notification) {
        let transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, transformState)
    }
}
