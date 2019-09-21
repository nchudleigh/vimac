//
//  ScrollMode.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 18/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class ScrollMode: NSObject, BaseModeProtocol {
    let overlayWindowController: NSWindowController
    var selectorTextField: OverlayTextField?
    var scrollTextField: OverlayTextField?
    let applicationWindow: UIElement
    let SCROLL_TEXT_FIELD_TAG = 2
    let SCROLL_SELECTOR_TEXT_FIELD_TAG = 3
    
    weak var delegate: ModeDelegate?

    required init(applicationWindow: UIElement) {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        overlayWindowController = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
        self.applicationWindow = applicationWindow
        
        // resize overlay window to same size as application window
        if let windowPosition: CGPoint = try! applicationWindow.attribute(.position),
            let windowSize: CGSize = try! applicationWindow.attribute(.size) {
            let origin = Utils.toOrigin(point: windowPosition, size: windowSize)
            let frame = NSRect(origin: origin, size: windowSize)
            overlayWindowController.window!.setFrame(frame, display: true, animate: false)
        }
    }
    
    func activate() {
        self.setSelectorMode()
    }
    
    func deactivate() {
        if let d = self.delegate {
            d.onDeactivate()
        }
    }

    func setSelectorMode() {
        self.selectorTextField = nil
        let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        textField.isHidden = true
        textField.tag = SCROLL_SELECTOR_TEXT_FIELD_TAG
        self.getWindow().contentView!.addSubview(textField)
        self.showWindow()
        textField.becomeFirstResponder()
        self.selectorTextField = textField
        self.setHintsAndBorders()
    }
    
    func setHintsAndBorders() {
        // show overlay window with borders around scroll areas
        let scrollAreas = traverseUIElementForScrollAreas(rootElement: self.applicationWindow)
        let borderViews: [BorderView] = scrollAreas
            .map { scrollArea in
                if let positionFlipped: CGPoint = try! scrollArea.attribute(.position),
                    let size: CGSize = try! scrollArea.attribute(.size) {
                    let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: size)
                    let positionRelativeToWindow = getWindow().convertPoint(fromScreen: positionRelativeToScreen)
                    return BorderView(frame: NSRect(origin: positionRelativeToWindow, size: size))
                }
                return nil
                // filters nil results
            }.compactMap({ $0 })
        let hintStrings = AlphabetHints().hintStrings(linkCount: borderViews.count)
        // map buttons to hint views to be added to overlay window
        var hintViews = [HintView]()
        if borderViews.count > 0 {
            for i in 1...borderViews.count {
                let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                text.initializeHint(hintText: hintStrings[i - 1], typed: "")
                hintViews.append(text)
            }
        }
        for (index, view) in borderViews.enumerated() {
            view.addSubview(hintViews[index])
            getWindow().contentView!.addSubview(view)
        }
    }
    
    func updateHintsAndBorders(typed: String) {
        if let borderViews = getWindow().contentView?.subviews.filter ({ $0 is BorderView }) as! [BorderView]? {
            borderViews.forEach { borderView in
                let hintView = borderView.subviews.first! as! HintView
                hintView.removeFromSuperview()
                if hintView.stringValue.starts(with: typed.uppercased()) {
                    let newHintView = HintView(frame: hintView.frame)
                    newHintView.initializeHint(hintText: hintView.stringValue, typed: typed.uppercased())
                    borderView.addSubview(newHintView)
                }
            }
        }
    }
    
    func setScrollMode(selectedBorder: BorderView) {
        self.selectorTextField = nil
        getWindow().contentView!.subviews.forEach { view in
            // remove borders and text field that the user did not select
            if view !== selectedBorder {
                view.removeFromSuperview()
            } else {
                // remove hint from selected border's subview
                for subview in view.subviews {
                    subview.removeFromSuperview()
                }
                selectedBorder.setActive()
            }
        }
        
        // move mouse to scroll area
        let mousePositionFlipped = getWindow().convertPoint(toScreen: selectedBorder.frame.origin)
        let mousePosition = NSPoint(x: mousePositionFlipped.x + 4, y: NSScreen.screens.first!.frame.size.height - mousePositionFlipped.y - 4)
        Utils.moveMouse(position: mousePosition)
        
        // set scrolling text field
        let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        textField.isEditable = true
        textField.delegate = self
        textField.isHidden = true
        textField.tag = SCROLL_TEXT_FIELD_TAG
        getWindow().contentView!.addSubview(textField)
        textField.becomeFirstResponder()
    }
    
    func traverseUIElementForScrollAreas(rootElement: UIElement) -> [UIElement] {
        var elements = [UIElement]()
        
        func fn(element: UIElement, level: Int) -> Void {
            let roleOptional: Role? = {
                do {
                    return try element.role();
                } catch {
                    return nil
                }
            }()
            
            if roleOptional == Role.scrollArea {
                elements.append(element)
                return
            }
            
            let children: [AXUIElement] = {
                do {
                    let childrenOptional = try element.attribute(Attribute.children) as [AXUIElement]?;
                    guard let children = childrenOptional else {
                        return []
                    }
                    return children
                } catch {
                    return []
                }
            }()
            children.forEach { child in
                fn(element: UIElement(child), level: level + 1)
            }
        }
        
        fn(element: rootElement, level: 1)
        return elements
    }
    
    func showWindow() {
        self.overlayWindowController.showWindow(nil)
        self.getWindow().makeKeyAndOrderFront(nil)
    }
    
    func getWindow() -> NSWindow {
        return self.overlayWindowController.window!
    }
    
    func removeSubviews() {
        getWindow().contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }
    
    func onScrollSelectorTextChange(textField: NSTextField) {
        let typed = textField.stringValue
        if let borderViews = getWindow().contentView?.subviews.filter ({ $0 is BorderView }) as! [BorderView]? {
            let borderViewsWithMatchingHint = borderViews.filter { borderView in
                let hintView = borderView.subviews.first! as! HintView
                return hintView.stringValue.starts(with: typed.uppercased())
            }
            if borderViewsWithMatchingHint.count == 0 && typed.count > 0 {
                self.deactivate()
                return
            }
            
            if borderViewsWithMatchingHint.count == 1 {
                let borderView = borderViewsWithMatchingHint.first!
                self.setScrollMode(selectedBorder: borderView)
                return
            }
            
            // update hints to reflect new typed text
            self.updateHintsAndBorders(typed: typed)
        }
    }
    
    func onScrollTextChange(textField: NSTextField) {
        let typed = textField.stringValue
        var yPixels: CGFloat = 0
        var xPixels: CGFloat = 0
        
        switch (typed.last?.uppercased()) {
        case "J":
            yPixels = -2
            xPixels = 0
        case "K":
            yPixels = 2
            xPixels = 0
        case "H":
            yPixels = 0
            xPixels = 2
        case "L":
            yPixels = 0
            xPixels = -2
        case "D":
            let borders = getWindow().contentView!.subviews.filter ({ $0 is BorderView }) as! [BorderView]
            if let firstBorder = borders.first {
                if borders.count == 1 && firstBorder.active {
                    yPixels = -1 * (firstBorder.frame.size.height / 2)
                    xPixels = 0
                }
            }
        case "U":
            let borders = getWindow().contentView!.subviews.filter ({ $0 is BorderView }) as! [BorderView]
            if let firstBorder = borders.first {
                if borders.count == 1 {
                    yPixels = firstBorder.frame.size.height / 2
                    xPixels = 0
                }
            }
        default:
            return
        }
        
        let event = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(yPixels), wheel2: Int32(xPixels), wheel3: 0)!
        event.post(tap: .cgSessionEventTap)
    }
}

extension ScrollMode : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        if textField.tag == SCROLL_SELECTOR_TEXT_FIELD_TAG {
            self.onScrollSelectorTextChange(textField: textField)
        } else if textField.tag == SCROLL_TEXT_FIELD_TAG {
            self.onScrollTextChange(textField: textField)
        }
    }
}
