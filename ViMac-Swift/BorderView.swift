//
//  BorderView.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 7/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class BorderView: NSView {
    let SIZE = CGFloat(2)
    let inactiveColor = NSColor.red
    let activeColor = NSColor.green
    var active = false

    override func draw(_ dirtyRect: NSRect) {
        let rect = cleanRect(dirtyRect: dirtyRect, size: SIZE)
        let border = NSBezierPath.init(rect: rect)
        border.lineWidth = SIZE
        
        if active {
            self.activeColor.set()
        } else {
            self.inactiveColor.set()
        }
        
        border.stroke()
    }

    func cleanRect(dirtyRect: NSRect, size: CGFloat) -> NSRect {
        return NSInsetRect(dirtyRect, size / 2.0, size / 2.0)
    }
    
    func setActive() {
        self.active = true
        self.display()
    }
}
