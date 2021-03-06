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

class StatusItemManager: NSObject {
    let menu: NSMenu
    let statusItem: NSStatusItem
    let preferencesWindowController: PreferencesWindowController
    
    init(preferencesWindowController: PreferencesWindowController) {
        self.menu = NSMenu()
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.button!.image = NSImage(named: "StatusBarButtonImage")
        self.preferencesWindowController = preferencesWindowController
        
        super.init()
        
        self.statusItem.menu = self.menu
        self.menu.delegate = self
    }
}

extension StatusItemManager : NSMenuDelegate {
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


class OldStatusItemManager: NSMenu, NSMenuDelegate, NSWindowDelegate {
    let statusItem: NSStatusItem
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
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.button?.image = NSImage(named: "StatusBarButtonImage")
        
        super.init(title: title)

        self.preferencesWindowController.window?.delegate = self
        self.statusItem.menu = self
        self.delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError()
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
extension OldStatusItemManager {
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
