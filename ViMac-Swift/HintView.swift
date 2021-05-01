//
//  HintView.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

let scale: CGFloat = 1.0  // adjust to debug at a larger size

class HintView: NSView {
    static let borderColor = NSColor.darkGray
    static let backgroundColor = NSColor(red: 255 / 255, green: 224 / 255, blue: 112 / 255, alpha: 1)
    static let untypedHintColor = NSColor.black
    static let typedHintColor = NSColor(red: 212 / 255, green: 172 / 255, blue: 58 / 255, alpha: 1)

    let associatedElement: Element
    var hintTextView: HintText?
    
    let borderWidth: CGFloat = 1.0 * scale
    let cornerRadius: CGFloat = 2.0 * scale

    required init(associatedElement: Element, hintTextSize: CGFloat, hintText: String, typedHintText: String) {
        self.associatedElement = associatedElement
        super.init(frame: .zero)

        self.hintTextView = HintText(hintTextSize: hintTextSize * scale, hintText: hintText, typedHintText: typedHintText)
        self.subviews.append(hintTextView!)

        self.wantsLayer = true
        

        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.hintTextView!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2 * borderWidth).isActive = true

        self.hintTextView!.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.widthAnchor.constraint(equalToConstant: width()).isActive = true
        self.heightAnchor.constraint(equalToConstant: height()).isActive = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let textWidth: CGFloat = self.hintTextView!.intrinsicContentSize.width
        let textHeight: CGFloat = self.hintTextView!.intrinsicContentSize.height
        let pointerLength: CGFloat = textHeight / 2  // as a fraction of the text height
        let pointerWidth: CGFloat = textHeight / 2  // as a fraction of the text _height_

        let border = NSBezierPath.init()

        border.lineWidth = borderWidth
        border.lineJoinStyle = .miter

        HintView.backgroundColor.setFill()
        HintView.borderColor.setStroke()

        border.move(to:NSPoint(x:borderWidth, y:cornerRadius + borderWidth))

        border.relativeLine(to:NSPoint(x:0,y:textHeight + borderWidth - 2 * cornerRadius))
        border.appendArc(withCenter: NSPoint(x:border.currentPoint.x + cornerRadius, y:border.currentPoint.y), radius: cornerRadius, startAngle: 180.0, endAngle: 90.0, clockwise: true)

        border.relativeLine(to:NSPoint(x:textWidth / 2.0 - cornerRadius - pointerWidth / 2.0, y: 0))

        border.relativeLine(to:NSPoint(x:pointerWidth/2.0, y: pointerLength))
        border.relativeLine(to:NSPoint(x:pointerWidth/2.0, y: -pointerLength))

        border.relativeLine(to:NSPoint(x:textWidth / 2.0 - cornerRadius - pointerWidth / 2.0, y: 0))


        border.appendArc(withCenter: NSPoint(x:border.currentPoint.x, y:border.currentPoint.y - cornerRadius), radius: cornerRadius, startAngle: 90.0, endAngle: 0.0, clockwise: true)

        border.relativeLine(to:NSPoint(x:0,y:-(textHeight + borderWidth - 2 * cornerRadius)))
        border.appendArc(withCenter: NSPoint(x:border.currentPoint.x - cornerRadius, y:border.currentPoint.y), radius: cornerRadius, startAngle: 0, endAngle: 270, clockwise: true)

        border.relativeLine(to:NSPoint(x:-(textWidth - 2 * cornerRadius),y: 0))
        border.appendArc(withCenter: NSPoint(x:border.currentPoint.x, y:border.currentPoint.y + cornerRadius), radius: cornerRadius, startAngle: 270.0, endAngle: 180.0, clockwise: true)

        border.fill()
        border.stroke()
    }

    private func width() -> CGFloat {
        return self.hintTextView!.intrinsicContentSize.width + 2 * borderWidth
    }
    
    private func height() -> CGFloat {
        self.hintTextView!.intrinsicContentSize.height * (1.5) + 2 * borderWidth
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
        attr.addAttributes([NSAttributedString.Key.foregroundColor : HintView.untypedHintColor], range: range)
        if hintText.lowercased().starts(with: typed.lowercased()) {
            let typedRange = NSMakeRange(0, typed.count)
            attr.addAttributes([NSAttributedString.Key.foregroundColor : HintView.typedHintColor], range: typedRange)
        }
        self.attributedStringValue = attr
    }
}
