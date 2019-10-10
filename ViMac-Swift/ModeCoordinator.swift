//
//  ModeCoordinator.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift

protocol Coordinator {
    var childCoordinators: [ModeCoordinator] { get set }
    var windowController: OverlayWindowController { get set }
}

class ModeCoordinator : Coordinator {
    var childCoordinators = [ModeCoordinator]()
    var windowController: OverlayWindowController
    var activeWindow: UIElement? = nil
    
    init(windowController: OverlayWindowController) {
        self.windowController = windowController
    }
    
    func setCurrentWindow(window: UIElement?) {
        self.exitMode()
        self.activeWindow = window
    }
    
    func exitMode() {
        if let vc = self.windowController.window?.contentViewController {
            vc.view.removeFromSuperview()
            self.windowController.window?.contentViewController = nil
        }
        self.windowController.close()
    }
    
    func setViewController(vc: ModeViewController) {
        vc.modeCoordinator = self
        self.windowController.window?.contentViewController = vc
        self.windowController.fitScreen()
        self.windowController.showWindow(nil)
        self.windowController.window?.makeKeyAndOrderFront(nil)
    }
    
    func setNormalMode() {
        let vc = NormalModeViewController.init()
        self.setViewController(vc: vc)
        vc.textField.becomeFirstResponder()
    }
    
    func setFocusMode() {
        guard let applicationWindow = activeWindow ?? Utils.getCurrentApplicationWindowManually() else {
            self.exitMode()
            return
        }
        
        let elementObservable = Utils.getUIElementChildrenRecursive(element: applicationWindow, parentScrollAreaFrame: nil)
            .filter({ element in
                do {
                    let roleOptional: String? = try element.attribute(.role)
                    guard let role = roleOptional else {
                        return false
                    }
                    return role == Role.textArea.rawValue || role == Role.textField.rawValue
                } catch {
                    return false
                }
            })
            .filter({ element in
                do {
                    return try element.attributeIsSettable(.focused)
                } catch {
                    return false
                }
            })

        elementObservable
            .toArray()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] elements in
                guard let window = self?.windowController.window else {
                    return
                }
                
                let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count)

                let hintViews: [HintView] = elements
                    .enumerated()
                    .map ({ (index, button) in
                        let positionFlippedOptional: NSPoint? = {
                            do {
                                return try button.attribute(.position)
                            } catch {
                                return nil
                            }
                        }()

                        if let positionFlipped = positionFlippedOptional {
                            let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                            text.initializeHint(hintText: hintStrings[index], typed: "")
                            let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                            let positionRelativeToWindow = window.convertPoint(fromScreen: positionRelativeToScreen)
                            text.associatedButton = button
                            text.frame.origin = positionRelativeToWindow
                            text.zIndex = index
                            return text
                        }
                        return nil })
                    .compactMap({ $0 })
                
                let vc = FocusModeViewController.init()
                vc.hintViews = hintViews
                self?.setViewController(vc: vc)
                vc.textField.becomeFirstResponder()
        })
    }
    
    func setScrollSelectorMode() {
        guard let applicationWindow = activeWindow ?? Utils.getCurrentApplicationWindowManually(),
            let window = self.windowController.window else {
            self.exitMode()
            return
        }
        
        var scrollAreas = Utils.traverseUIElementForScrollAreas(rootElement: applicationWindow)
        
        let hintStrings = AlphabetHints().hintStrings(linkCount: scrollAreas.count)

        let hintViews: [HintView] = scrollAreas
            .enumerated()
            .map ({ (index, button) in
                let positionFlippedOptional: NSPoint? = {
                    do {
                        return try button.attribute(.position)
                    } catch {
                        return nil
                    }
                }()

                if let positionFlipped = positionFlippedOptional {
                    let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                    text.initializeHint(hintText: hintStrings[index], typed: "")
                    let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                    let positionRelativeToWindow = window.convertPoint(fromScreen: positionRelativeToScreen)
                    text.associatedButton = button
                    text.frame.origin = positionRelativeToWindow
                    text.zIndex = index
                    return text
                }
                return nil })
            .compactMap({ $0 })
        
        let vc = ScrollSelectorModeViewController.init()
        vc.hintViews = hintViews
        self.setViewController(vc: vc)
        vc.textField.becomeFirstResponder()
    }
    
    func setScrollMode() {
        let vc = ScrollModeViewController.init()
        self.setViewController(vc: vc)
        vc.textField.becomeFirstResponder()
    }
    
    func setCursorMode(cursorAction: CursorAction, cursorSelector: CursorSelector, allowedRoles: [Role]) {
        guard let applicationWindow = activeWindow ?? Utils.getCurrentApplicationWindowManually(),
            let window = self.windowController.window else {
            self.exitMode()
            return
        }

        let blacklistedRoles = Set(["AXUnknown", "AXToolbar", "AXCell", "AXWindow", "AXScrollArea", "AXSplitter", "AXList"])
        let allowedRolesString = Set(allowedRoles.map({ $0.rawValue }))

        var elements = Utils.getUIElementChildrenRecursive(element: applicationWindow, parentScrollAreaFrame: nil)
        if allowedRoles.count > 0 {
            elements = elements.filter({ element in
                do {
                    guard let elementRole: String = try element.attribute(.role) else {
                        return false
                    }
                    return !blacklistedRoles.contains(elementRole) && allowedRolesString.contains(elementRole)
                } catch {
                    return false
                }
            })
        }
        
        let menuBarElements = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        
        let allElements = Observable.merge(elements, menuBarElements)

        let vc = CursorModeViewController.init()
        vc.elements = allElements
        vc.allowedRoles = allowedRoles
        vc.cursorSelector = cursorSelector
        vc.cursorAction = cursorAction
        self.setViewController(vc: vc)

    }
}
