//
//  PreferencesGeneralViewController.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 22/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import MASShortcut

class PreferencesGeneralViewController: NSViewController {
    
    @IBOutlet weak var shortcutView: MASShortcutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shortcutView.associatedUserDefaultsKey = Utils.commandShortcutKey
    }
    
}
