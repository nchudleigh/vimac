//
//  HintView.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class HintView: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initializeHint(hintText: String, positionFlipped: NSPoint, window: NSWindow) {
        self.stringValue = hintText
        self.wantsLayer = true
        self.isBordered = true
        self.drawsBackground = true
        
        let backgroundColor = NSColor(red: 255 / 255, green: 197 / 255, blue: 66 / 255, alpha: 1)
        let textColor = NSColor.black
        
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.layer?.backgroundColor = backgroundColor.cgColor
        self.layer?.borderColor = backgroundColor.cgColor
        self.layer?.borderWidth = 1
        self.layer?.cornerRadius = 5
        self.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        
        self.sizeToFit()
        
        let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: self.frame.size)
        let positionRelativeToWindow = window.convertPoint(fromScreen: positionRelativeToScreen)
        self.frame.origin = positionRelativeToWindow
    }
}
