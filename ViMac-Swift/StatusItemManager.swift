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
            menu.addItem(withTitle: "Manual", action: #selector(manualClick), keyEquivalent: "").target = self
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

    @objc func manualClick() {
        let url = URL(string: "https://vimacapp.com/manual")!
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
