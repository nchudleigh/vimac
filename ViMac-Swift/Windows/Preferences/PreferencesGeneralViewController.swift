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
    @IBOutlet weak var scrollSensitivitySlider: NSSlider!
    @IBOutlet weak var shortcutView: MASShortcutView!
    
    override func viewWillAppear() {
        scrollSensitivitySlider.integerValue = UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shortcutView.associatedUserDefaultsKey = Utils.commandShortcutKey
    }
    @IBAction func sliderChanged(_ sender: Any) {
        UserDefaults.standard.set(scrollSensitivitySlider.integerValue, forKey: Utils.scrollSensitivityKey)
    }
}
