//
//  PreferencesGeneralViewController.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 22/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import MASShortcut

class PreferencesGeneralViewController: NSViewController {
    @IBOutlet weak var scrollSensitivitySlider: NSSlider!
    @IBOutlet weak var hintModeShortcut: MASShortcutView!
    @IBOutlet weak var scrollModeShortcut: MASShortcutView!
    @IBOutlet weak var reverseVerticalScroll: NSButton!
    @IBOutlet weak var reverseHorizontalScroll: NSButton!
    @IBOutlet weak var forceKeyboardLayout: NSPopUpButton!
    let inputSources = InputSourceManager.inputSources
    
    override func viewWillAppear() {
        scrollSensitivitySlider.integerValue = UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey)
        reverseVerticalScroll.state = UserDefaults.standard.bool(forKey: Utils.isVerticalScrollReversedKey) ? .on : .off
        reverseHorizontalScroll.state = UserDefaults.standard.bool(forKey: Utils.isHorizontalScrollReversedKey) ? .on : .off
        
        let menuItems = inputSources.map({ source -> NSMenuItem in
            let menuItem = NSMenuItem.init()
            menuItem.title = source.name
            menuItem.representedObject = source
            return menuItem
        })
        
        let emptyMenuItem = NSMenuItem.init()
        emptyMenuItem.title = ""
        forceKeyboardLayout.menu?.addItem(emptyMenuItem)
        for menu in menuItems {
            forceKeyboardLayout.menu?.addItem(menu)
        }
        
        let currentForcedKeyboardLayoutId = UserDefaults.standard.string(forKey: Utils.forceKeyboardLayoutKey)
        if currentForcedKeyboardLayoutId == nil {
            forceKeyboardLayout.selectItem(at: 0)
        } else {
            let i = inputSources.firstIndex(where: { $0.id == currentForcedKeyboardLayoutId })
            if let i = i {
                forceKeyboardLayout.selectItem(at: i + 1)
            } else {
                forceKeyboardLayout.selectItem(at: 0)
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hintModeShortcut.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        scrollModeShortcut.associatedUserDefaultsKey = Utils.scrollModeShortcutKey
    }

    @IBAction func sliderChanged(_ sender: Any) {
        UserDefaults.standard.set(scrollSensitivitySlider.integerValue, forKey: Utils.scrollSensitivityKey)
    }

    @IBAction func reverseVerticalScrollChanged(_ sender: Any) {
        let isScrollReversed = reverseVerticalScroll.state == .on
        UserDefaults.standard.set(isScrollReversed, forKey: Utils.isVerticalScrollReversedKey)
    }

    @IBAction func reverseHorizontalScrollChange(_ sender: Any) {
        let isScrollReversed = reverseHorizontalScroll.state == .on
        UserDefaults.standard.set(isScrollReversed, forKey: Utils.isHorizontalScrollReversedKey)
    }

    @IBAction func onForceKeyboardLayoutChange(_ sender: Any) {
        let newInputSource = forceKeyboardLayout.selectedItem?.representedObject as? InputSource?
        UserDefaults.standard.set(newInputSource??.id, forKey: Utils.forceKeyboardLayoutKey)
    }
}
