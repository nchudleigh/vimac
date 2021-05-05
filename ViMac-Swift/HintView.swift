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
    let borderColor = NSColor.darkGray
    let backgroundColor = NSColor(red: 255 / 255, green: 224 / 255, blue: 112 / 255, alpha: 1)
    let untypedHintColor = NSColor.black
    let typedHintColor = NSColor(red: 212 / 255, green: 172 / 255, blue: 58 / 255, alpha: 1)

    let associatedElement: Element
    var hintTextView: HintText?
    
    let borderWidth: CGFloat = 1.0
    let cornerRadius: CGFloat = 3.0

    required init(associatedElement: Element, hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        self.associatedElement = associatedElement
        super.init(frame: .zero)

        self.hintTextView = HintText(hintTextSize: hintTextSize, hintText: hintText, typedHintText: typedHintText, untypedHintColor: untypedHintColor, typedHintColor: typedHintColor)
        self.subviews.append(hintTextView!)

        self.wantsLayer = true
        
        
        self.layer?.borderWidth = borderWidth
        
        self.layer?.backgroundColor = backgroundColor.cgColor
        self.layer?.borderColor = borderColor.cgColor
        self.layer?.cornerRadius = cornerRadius

        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.hintTextView!.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.hintTextView!.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.widthAnchor.constraint(equalToConstant: width()).isActive = true
        self.heightAnchor.constraint(equalToConstant: height()).isActive = true
    }
    
    private func width() -> CGFloat {
        return self.hintTextView!.intrinsicContentSize.width + 2 * borderWidth
    }
    
    private func height() -> CGFloat {
        self.hintTextView!.intrinsicContentSize.height + 2 * borderWidth
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init(frame frameRect: NSRect) {
        fatalError()
    }
    
    override var intrinsicContentSize: NSSize {
        return .init(
            width: width(),
            height: height()
        )
    }
    
    func updateTypedText(typed: String) {
        self.hintTextView!.updateTypedText(typed: typed)
    }
}

class HintText: NSTextField {
    let untypedHintColor: NSColor
    let typedHintColor: NSColor

    required init(hintTextSize: CGFloat, hintText: String, typedHintText: String, untypedHintColor: NSColor, typedHintColor: NSColor) {
        self.untypedHintColor = untypedHintColor
        self.typedHintColor = typedHintColor
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
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
        
        self.isEditable = false
    }
    
    func updateTypedText(typed: String) {
        let hintText = self.attributedStringValue.string
        let attr = NSMutableAttributedString(string: hintText)
        let range = NSMakeRange(0, hintText.count)
        attr.addAttributes([NSAttributedString.Key.foregroundColor : untypedHintColor], range: range)
        if hintText.lowercased().starts(with: typed.lowercased()) {
            let typedRange = NSMakeRange(0, typed.count)
            attr.addAttributes([NSAttributedString.Key.foregroundColor : typedHintColor], range: typedRange)
        }
        self.attributedStringValue = attr
    }
}
