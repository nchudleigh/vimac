//
//  HintMode.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 18/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxCocoa
import RxSwift

class HintMode: NSObject, BaseModeProtocol {
    let overlayWindowController: NSWindowController
    var selectorTextField: OverlayTextField?
    let applicationWindow: UIElement
    var pressableElementByHint: [String : UIElement]
    
    weak var delegate: ModeDelegate?

    let HINT_TEXT_FIELD_TAG = 1
    
    required init(applicationWindow: UIElement) {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        overlayWindowController = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
        self.applicationWindow = applicationWindow
        self.pressableElementByHint = [String : UIElement]()
        
        // resize overlay window to same size as application window
        if let windowPosition: CGPoint = try! applicationWindow.attribute(.position),
            let windowSize: CGSize = try! applicationWindow.attribute(.size) {
            let origin = Utils.toOrigin(point: windowPosition, size: windowSize)
            let frame = NSRect(origin: origin, size: windowSize)
            overlayWindowController.window!.setFrame(frame, display: true, animate: false)
        }
    }
    
    func showWindow() {
        self.overlayWindowController.showWindow(nil)
        self.getWindow().makeKeyAndOrderFront(nil)
    }
    
    func getWindow() -> NSWindow {
        return self.overlayWindowController.window!
    }
    
    func activate() {
        self.setSelectorMode()
    }
    
    func deactivate() {
        self.overlayWindowController.close()
        self.removeSubviews()
        if let d = self.delegate {
            d.onDeactivate()
        }
    }
    
    func removeSubviews() {
        getWindow().contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }
    
    func setSelectorMode() {
        let pressableElements = traverseUIElementForPressables(element: self.applicationWindow, level: 1)
        let hintStrings = AlphabetHints().hintStrings(linkCount: pressableElements.count)
        // map buttons to hint views to be added to overlay window
        let hintViews: [HintView] = pressableElements
            .enumerated()
            .map { (index, button) in
                if let positionFlipped: CGPoint = try! button.attribute(.position) {
                    let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                    text.initializeHint(hintText: hintStrings[index], typed: "")
                    let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                    let positionRelativeToWindow = getWindow().convertPoint(fromScreen: positionRelativeToScreen)
                    text.frame.origin = positionRelativeToWindow
                    self.pressableElementByHint[hintStrings[index]] = button
                    return text
                }
                return nil
                // filters nil results
            }.compactMap({ $0 })
        
        hintViews.forEach { view in
            // add view to overlay window
            getWindow().contentView!.addSubview(view)
        }
        
        let selectorTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        selectorTextField.stringValue = ""
        selectorTextField.isEditable = true
        selectorTextField.delegate = self
        selectorTextField.isHidden = true
        selectorTextField.tag = HINT_TEXT_FIELD_TAG
        getWindow().contentView?.addSubview(selectorTextField)
        self.overlayWindowController.showWindow(nil)
        getWindow().makeKeyAndOrderFront(nil)
        selectorTextField.becomeFirstResponder()
        
    }
    
    func traverseUIElementForPressables(element: UIElement, level: Int) -> [UIElement] {
        let actionsOptional: [Action]? = {
            do {
                return try element.actions();
            } catch {
                return nil
            }
        }()
        
        let roleOptional: Role? = {
            do {
                return try element.role()
            } catch {
                return nil
            }
        }()
        
        // ignore subcomponents of a scrollbar
        if let role = roleOptional {
            if role == .scrollBar {
                return []
            }
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
        
        let recursiveChildren = children
            .map({child -> [UIElement] in
                return traverseUIElementForPressables(element: UIElement.init(child), level: level + 1)
            })
            .reduce([]) {(result, next) -> [UIElement] in
                return result + next
        }
        
        if let actions = actionsOptional {
            if (actions.contains(.press)) {
                return [element] + recursiveChildren
            }
        }
        
        return recursiveChildren
    }

    func updateHints(typed: String) {
        if let hintViews = getWindow().contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? {
            hintViews.forEach { hintView in
                hintView.removeFromSuperview()
                if hintView.stringValue.starts(with: typed.uppercased()) {
                    let newHintView = HintView(frame: hintView.frame)
                    newHintView.initializeHint(hintText: hintView.stringValue, typed: typed.uppercased())
                    getWindow().contentView!.addSubview(newHintView)
                }
            }
        }
    }
    
    func onHintSelectorTextChange(textField: NSTextField) {
        let typed = textField.stringValue
        if let hintViews = getWindow().contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? {
            let matchingHints = hintViews.filter { hintView in
                return hintView.stringValue.starts(with: typed.uppercased())
            }

            if matchingHints.count == 0 && typed.count > 0 {
                self.deactivate()
                return
            }
            
            if matchingHints.count == 1 {
                let matchingHint = matchingHints.first!
                let button = pressableElementByHint[matchingHint.stringValue]!
                let o: Observable<Void> = Observable.just(Void())
                o
                    .subscribeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { x in
                        do {
                            try button.performAction(.press)
                        } catch {
                        }
                    })
                self.deactivate()
                return
            }
            
            // update hints to reflect new typed text
            self.updateHints(typed: typed)
        }
    }
}

extension HintMode : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        // this check is redundant since there is only one type of text field unlike ScrollMode
        if textField.tag == HINT_TEXT_FIELD_TAG {
            self.onHintSelectorTextChange(textField: textField)
        }
    }
}
