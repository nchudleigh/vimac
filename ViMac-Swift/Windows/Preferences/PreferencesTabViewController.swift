//
//  PreferencesTabViewController.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 19/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class PreferencesTabViewController: NSTabViewController {
    var currentTabViewController: NSViewController?
    var currentWindowController: NSWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
//        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
//        currentWindowController = storyboard.instantiateController(withIdentifier: "PreferencesWindowController") as! NSWindowController
//        currentTabViewController = storyboard.instantiateController(withIdentifier: "scroll_mode") as! NSViewController
//        let currentWindowRect = currentWindowController!.window!.frame
//        let generalSize = NSMakeRect(currentWindowRect.origin.x, currentWindowRect.origin.y, 450, 265)
//        currentWindowController!.window!.setFrame(generalSize, display: true, animate: true)
    }
    
}
