//
//  OverlayWindowController.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class OverlayWindowController: NSWindowController {
    
    init() {
        super.init(window: OverlayWindow())
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func fitToFrame(_ frame: NSRect) {
        self.window?.setFrame(frame, display: true, animate: false)
    }
    
}
    
