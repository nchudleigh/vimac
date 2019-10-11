//
//  OverlayWindowController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class OverlayWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func fitScreen() {
        self.window?.setFrame(NSScreen.main!.frame, display: true, animate: false)
    }
}
