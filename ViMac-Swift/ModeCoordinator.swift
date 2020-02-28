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
        
        guard let windowSize: NSSize = try? applicationWindow.attribute(.size),
            let windowPosition: NSPoint = try? applicationWindow.attribute(.position) else {
                self.exitMode()
                return
        }
        
        let windowFrame = NSRect(origin: windowPosition, size: windowSize)
        var windowElements = Utils.getUIElementChildrenRecursive(element: applicationWindow, parentContainerFrame: windowFrame)
        let menuBarElements = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        let extraMenuBarElements = Utils.traverseForExtraMenuBarItems()
        
        let allElements = Observable.merge(windowElements, menuBarElements, extraMenuBarElements)
        let vc = HintModeViewController.init(elements: allElements)
        self.setViewController(vc: vc)
    }
}
