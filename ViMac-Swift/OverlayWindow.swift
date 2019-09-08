//
//  OverlayWindow.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 8/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSZeroRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .popUpMenu
        self.ignoresMouseEvents = true
    }
}
