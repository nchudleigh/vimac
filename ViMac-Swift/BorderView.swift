//
//  BorderView.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 7/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class BorderView: NSView {
    let SIZE = CGFloat(1)

    override func draw(_ dirtyRect: NSRect) {
        let rect = cleanRect(dirtyRect: dirtyRect, size: SIZE)
        let border = NSBezierPath.init(rect: rect)
        border.lineWidth = SIZE
        NSColor.red.set()
        border.stroke()
    }

    func cleanRect(dirtyRect: NSRect, size: CGFloat) -> NSRect {
        return NSInsetRect(dirtyRect, size / 2.0, size / 2.0)
    }
}
