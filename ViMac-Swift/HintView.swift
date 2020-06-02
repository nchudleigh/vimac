//
//  HintView.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class HintView: NSView {
    static let borderColor = NSColor(red: 212 / 255, green: 172 / 255, blue: 58 / 255, alpha: 1)
    static let backgroundColor = NSColor(red: 255 / 255, green: 224 / 255, blue: 112 / 255, alpha: 1)
    static let untypedHintColor = NSColor.black
    static let typedHintColor = NSColor(red: 212 / 255, green: 172 / 255, blue: 58 / 255, alpha: 1)

    let associatedElement: UIElement
    var hintTextView: HintText?

    required init(associatedElement: UIElement, hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        self.associatedElement = associatedElement

        super.init(frame: .zero)

        setTheme()

        addHintText(hintTextSize: hintTextSize, hintText: hintText, typedHintText: typedHintText)
        self.frame = self.hintTextView!.frame
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func setTheme() {
        self.wantsLayer = true

        self.layer?.backgroundColor = HintView.backgroundColor.cgColor
        self.layer?.borderColor = HintView.borderColor.cgColor
        self.layer?.cornerRadius = 3
        self.layer?.borderWidth = 1
    }

    func addHintText(hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        self.hintTextView = HintText(hintTextSize: hintTextSize, hintText: hintText, typedHintText: typedHintText)
        self.subviews.append(hintTextView!)
    }
    
    func updateTypedText(typed: String) {
        self.hintTextView!.updateTypedText(typed: typed)
    }
}

class HintText: NSTextField {

    required init(hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        super.init(frame: .zero)
        
        self.setup(hintTextSize: hintTextSize, hintText: hintText, typedHintText: typedHintText)
    }

    required init(coder: NSCoder) {
        fatalError()
    }
    
    func setup(hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        self.stringValue = hintText
        self.font = NSFont.systemFont(ofSize: hintTextSize, weight: .bold)
        self.textColor = .black

        // isBezeled causes unwanted padding.
        self.isBezeled = false
        
        // fixes black background caused by setting isBezeled
        self.drawsBackground = true
        self.wantsLayer = true
        self.backgroundColor = NSColor.clear
        
        // fixes blurry text
        self.canDrawSubviewsIntoLayer = true
        
        self.sizeToFit()
    }
    
    func updateTypedText(typed: String) {
        let hintText = self.attributedStringValue.string
        let attr = NSMutableAttributedString(string: hintText)
        let range = NSMakeRange(0, hintText.count)
        attr.addAttributes([NSAttributedString.Key.foregroundColor : HintView.untypedHintColor], range: range)
        if hintText.lowercased().starts(with: typed.lowercased()) {
            let typedRange = NSMakeRange(0, typed.count)
            attr.addAttributes([NSAttributedString.Key.foregroundColor : HintView.typedHintColor], range: typedRange)
        }
        self.attributedStringValue = attr
    }
}
