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

class StatusItemManager: NSMenu, NSMenuDelegate {
    static let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    lazy var controller = PreferencesWindowController(
        preferencePanes: [
            GeneralPreferenceViewController(),
            HintModePreferenceViewController(),
            ScrollModePreferenceViewController(),
        ],
        style: .segmentedControl
    )
    
    override func awakeFromNib() {
        guard let button = StatusItemManager.statusItem.button else {
            return
        }
        button.image = NSImage(named: "StatusBarButtonImage")
        StatusItemManager.statusItem.menu = self
        StatusItemManager.statusItem.menu?.delegate = self
    }
    
    func menuWillOpen(_ _menu: NSMenu) {
        if let menu = StatusItemManager.statusItem.menu {
            menu.removeAllItems()
            menu.addItem(withTitle: "Preferences", action: #selector(preferencesClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Check for updates", action: #selector(checkForUpdatesClick), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit", action: #selector(quitClick), keyEquivalent: "").target = self
        }
    }
    
    @objc func preferencesClick() {
        controller.show()
    }
    
    @objc func checkForUpdatesClick() {
        SUUpdater.shared()?.checkForUpdates(nil)
    }
    
    @objc func quitClick() {
        NSApplication.shared.terminate(self)
    }
}
