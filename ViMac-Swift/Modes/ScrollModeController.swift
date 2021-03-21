//
//  ScrollModeController.swift
//  Vimac
//
//  Created by Dexter Leng on 21/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

class ScrollModeController: ModeController {
    weak var delegate: ModeControllerDelegate?
    private var activated = false
    
    private var windowController: OverlayWindowController?
    private var viewController: ScrollModeViewController?
    
    let window: Element
    
    init(window: Element) {
        self.window = window
    }
    
    func activate() {
        if activated { return }
        activated = true
        
        let wc = OverlayWindowController()
        let vc = ScrollModeViewController(window: window)
        
        let focusedWindowFrame = GeometryUtils.convertAXFrameToGlobal(window.frame)
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindowFrame)

        wc.window?.contentViewController = vc
        wc.fitToFrame(screenFrame)
        wc.showWindow(nil)
        wc.window?.makeKeyAndOrderFront(nil)
        
        vc.delegate = self
        
        self.windowController = wc
        self.viewController = vc
    }
    
    func deactivate() {
        if !activated { return }
        activated = false
        
        let wc = self.windowController!
        let vc = self.viewController!

        self.windowController = nil
        self.viewController = nil
        
        vc.view.removeFromSuperview()
        wc.window?.contentViewController = nil
        wc.close()
        
        self.delegate?.modeDeactivated(controller: self)
    }
    
    private func activeScreenFrame(focusedWindowFrame: NSRect) -> NSRect {
        // When the focused window is in full screen mode in a secondary display,
        // NSScreen.main will point to the primary display.
        // this is a workaround.
        var activeScreen = NSScreen.main!
        var maxArea: CGFloat = 0
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(focusedWindowFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                activeScreen = screen
            }
        }
        return activeScreen.frame
    }
}
