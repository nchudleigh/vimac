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
import Segment

class StatusItemManager: NSObject {
    let menu: NSMenu
    let statusItem: NSStatusItem
    let preferencesWindowController: PreferencesWindowController
    
    init(preferencesWindowController: PreferencesWindowController) {
        self.menu = NSMenu()
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.button!.image = NSImage(named: "StatusBarButtonImage")
        self.preferencesWindowController = preferencesWindowController
        self.preferencesWindowController.window?.delegate = self.preferencesWindowController
        
        super.init()
        
        self.statusItem.menu = self.menu
        self.menu.delegate = self
    }
}

extension PreferencesWindowController: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        Analytics.shared().identify(nil, traits: [
            "Launch At Login": UserDefaults.standard.bool(forKey: Utils.shouldLaunchOnStartupKey),
            "Force KB Layout ID": UserDefaults.standard.string(forKey: Utils.forceKeyboardLayoutKey),
            "Hint Mode Key Sequence Enabled": UserDefaultsProperties.keySequenceHintModeEnabled.read(),
            "Scroll Mode Key Sequence Enabled": UserDefaultsProperties.keySequenceScrollModeEnabled.read(),
            "Non Native Support Enabled": UserDefaultsProperties.AXEnhancedUserInterfaceEnabled.read(),
            "Electron Support Enabled": UserDefaultsProperties.AXManualAccessibilityEnabled.read()
        ])
    }
}

extension StatusItemManager : NSMenuDelegate {
    func menuWillOpen(_ _menu: NSMenu) {
        if let menu = statusItem.menu {
            menu.removeAllItems()
            menu.addItem(withTitle: "Getting Started", action: #selector(gettingStartedClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Report bugs / Suggest features", action: #selector(openGithubIssues), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Follow Vimac on Twitter", action: #selector(followVimacClick), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(withTitle: "About", action: #selector(aboutClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Preferences", action: #selector(preferencesClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Check for updates", action: #selector(checkForUpdatesClick), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit", action: #selector(quitClick), keyEquivalent: "").target = self
        }
    }
    
    @objc func preferencesClick() {
        preferencesWindowController.show()
    }
    
    @objc func aboutClick() {
        preferencesWindowController.show(preferencePane: .about)
    }
    
    @objc func gettingStartedClick() {
        let url = URL(string: "https://github.com/dexterleng/vimac#getting-started")!
        _ = NSWorkspace.shared.open(url)
    }
    
    @objc func followVimacClick() {
        let url = URL(string: "https://twitter.com/vimacapp")!
        _ = NSWorkspace.shared.open(url)
    }
    
    @objc func openGithubIssues() {
        let url = URL(string: "https://github.com/dexterleng/vimac/issues")!
        _ = NSWorkspace.shared.open(url)
    }
    
    @objc func checkForUpdatesClick() {
        SUUpdater.shared()?.checkForUpdates(nil)
    }
    
    @objc func quitClick() {
        NSApplication.shared.terminate(self)
    }
}
