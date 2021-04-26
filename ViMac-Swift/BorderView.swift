//
//  BorderView.swift
//  Vimac
//
//  Created by Dexter Leng on 1/12/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class BorderView: NSView {
    let SIZE = CGFloat(3)
    let borderColor = UserDefaultsProperties.scrollFrameColor.read()

    override func draw(_ dirtyRect: NSRect) {
        let rect = cleanRect(dirtyRect: dirtyRect, size: SIZE)
        let border = NSBezierPath.init(rect: rect)
        border.lineWidth = SIZE
        self.borderColor.set()
        border.stroke()
    }

    func cleanRect(dirtyRect: NSRect, size: CGFloat) -> NSRect {
        return NSInsetRect(dirtyRect, size / 2.0, size / 2.0)
    }
}
