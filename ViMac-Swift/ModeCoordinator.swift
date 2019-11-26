//
//  ModeCoordinator.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift

protocol Coordinator {
    var windowController: OverlayWindowController { get set }
}

class ModeCoordinator : Coordinator {
    var windowController: OverlayWindowController
    
    init(windowController: OverlayWindowController) {
        self.windowController = windowController
    }
    
    func setCurrentWindow(window: UIElement?) {
        self.exitMode()
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

    func setScrollSelectorMode() {
        guard let applicationWindow = Utils.getCurrentApplicationWindowManually(),
            let window = self.windowController.window else {
            self.exitMode()
            return
        }
        
        let scrollAreas = Utils.traverseUIElementForScrollAreas(rootElement: applicationWindow)
        
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
                    text.associatedElement = button
                    text.frame.origin = positionRelativeToWindow
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
    
    func setHintMode() {
        guard let applicationWindow = Utils.getCurrentApplicationWindowManually(),
            let window = self.windowController.window else {
            self.exitMode()
            return
        }
        var windowElements = Utils.getUIElementChildrenRecursive(element: applicationWindow, parentScrollAreaFrame: nil)
        let menuBarElements = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        let allElements = Observable.merge(windowElements, menuBarElements)
        let vc = HintModeViewController.init(elements: allElements)
        self.setViewController(vc: vc)
    }
}
