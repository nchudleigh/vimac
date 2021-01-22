//
//  ModeCoordinator.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Carbon
import Cocoa
import AXSwift
import RxSwift

protocol Coordinator {
    var windowController: OverlayWindowController { get set }
}

class ModeCoordinator : Coordinator {
    var priorKBLayout: InputSource?
    var forceKBLayout: InputSource?
    var forceKBLayoutObservation: NSKeyValueObservation?
    
    var windowController: OverlayWindowController
    
    init(windowController: OverlayWindowController) {
        self.windowController = windowController
        self.forceKBLayoutObservation = observeForceKBInputSource()
    }
    
    func exitMode() {
        guard let vc = self.windowController.window?.contentViewController else {
            return
        }
        
        if self.forceKBLayout != nil {
            self.priorKBLayout?.select()
        }

        vc.view.removeFromSuperview()
        self.windowController.window?.contentViewController = nil
        self.windowController.close()
    }
    
    func setViewController(vc: ModeViewController, screenFrame: NSRect) {
        vc.modeCoordinator = self
        self.windowController.window?.contentViewController = vc
        self.windowController.fitToFrame(screenFrame)
        self.windowController.showWindow(nil)
        self.windowController.window?.makeKeyAndOrderFront(nil)
    }
    
    func setScrollMode() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
            let focusedWindow = focusedWindow(app: frontmostApp) else {
            self.exitMode()
            return
        }
        
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindow.frame)
        
        self.priorKBLayout = InputSourceManager.currentInputSource()
        if let forceKBLayout = self.forceKBLayout {
            forceKBLayout.select()
        }

        let vc = ScrollModeViewController.init(window: focusedWindow)
        self.setViewController(vc: vc, screenFrame: screenFrame)
    }
    
    func setHintMode() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
            let focusedWindow = focusedWindow(app: frontmostApp) else {
            self.exitMode()
            return
        }
        
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindow.frame)
        
        self.priorKBLayout = InputSourceManager.currentInputSource()
        if let forceKBLayout = self.forceKBLayout {
            forceKBLayout.select()
        }

        let vc = HintModeViewController.init(app: frontmostApp, window: focusedWindow)
        self.setViewController(vc: vc, screenFrame: screenFrame)
    }
    
    func observeForceKBInputSource() -> NSKeyValueObservation {
        let observation = UserDefaults.standard.observe(\.ForceKeyboardLayout, options: [.initial, .new], changeHandler: { [weak self] (a, b) in
            let id = b.newValue
            var inputSource: InputSource? = nil
            if let id = id {
                inputSource = InputSourceManager.inputSources.first(where: { $0.id == id })
            }
            self?.forceKBLayout = inputSource
        })
        return observation
    }
    
    private func focusedWindow(app: NSRunningApplication) -> Element? {
        let axAppOptional = Application.init(app)
        guard let axApp = axAppOptional else { return nil }
        
        let axWindowOptional: UIElement? = try? axApp.attribute(.focusedWindow)
        guard let axWindow = axWindowOptional else { return nil }
        
        return Element.initialize(rawElement: axWindow.element)
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

extension UserDefaults
{
    @objc dynamic var ForceKeyboardLayout: String?
    {
        get {
            return string(forKey: Utils.forceKeyboardLayoutKey)
        }
        set {
            set(newValue, forKey: Utils.forceKeyboardLayoutKey)
        }
    }

}
