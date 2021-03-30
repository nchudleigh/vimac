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
import Segment
import os

class ModeCoordinator: ModeControllerDelegate {
    let disposeBag = DisposeBag()
    
    var priorKBLayout: InputSource?
    var forceKBLayout: InputSource?
    var forceKBLayoutObservation: NSKeyValueObservation?
    
    let scrollModeKeySequence: [Character] = ["j", "k"]
    let hintModeKeySequence: [Character] = ["f", "d"]
    private let keySequenceListener: VimacKeySequenceListener
    
    var modeController: ModeController?
    
    init() {
        self.keySequenceListener = VimacKeySequenceListener()
        self.keySequenceListener.start()
        
        self.forceKBLayoutObservation = observeForceKBInputSource()
        
        disposeBag.insert(keySequenceListener.scrollMode.bind(onNext: { [weak self] _ in
            self?.setScrollMode()
        }))
        
        disposeBag.insert(keySequenceListener.hintMode.bind(onNext: { [weak self] _ in
            self?.setHintMode()
        }))
    }

    func onKeySequenceTyped(sequence: [Character]) {
        if sequence == scrollModeKeySequence {
            setScrollMode()
        } else if sequence == hintModeKeySequence {
            setHintMode()
        }
    }
    
    func deactivate() {
        self.modeController?.deactivate()
    }
    
    func beforeModeActivation() {
        self.priorKBLayout = InputSourceManager.currentInputSource()
        if let forceKBLayout = self.forceKBLayout {
            forceKBLayout.select()
        }
        
        keySequenceListener.stop()

        os_log("[beforeModeActivation]: priorKBLayout=%@, forceKBLayout=%@", log: Log.accessibility, self.priorKBLayout?.id ?? "nil", self.forceKBLayout?.id ?? "nil")
    }
    
    func modeDeactivated(controller: ModeController) {
        self.modeController = nil
        
        if self.forceKBLayout != nil {
            self.priorKBLayout?.select()
        }
        
        keySequenceListener.start()
        
        os_log("[modeDeactivated]: priorKBLayout=%@, forceKBLayout=%@", log: Log.accessibility, self.priorKBLayout?.id ?? "nil", self.forceKBLayout?.id ?? "nil")
    }

    func setScrollMode() {
        if let modeController = modeController {
            modeController.deactivate()
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
            let focusedWindow = focusedWindow(app: frontmostApp) else {
            return
        }
        
        // the app crashes when talking to its own accessibility server
        let isTargetVimac = frontmostApp.bundleIdentifier == Bundle.main.bundleIdentifier
        if isTargetVimac {
            return
        }
        
        beforeModeActivation()
        
        Analytics.shared().track("Scroll Mode Activated", properties: [
            "Target Application": frontmostApp.bundleIdentifier as Any
        ])
        
        modeController = ScrollModeController(window: focusedWindow)
        modeController?.delegate = self
        modeController!.activate()
    }
    
    func setHintMode() {
        if let modeController = modeController {
            modeController.deactivate()
        }
        
        let app = NSWorkspace.shared.frontmostApplication
        let window = app.flatMap { focusedWindow(app: $0) }
        
        if let app = app {
            // the app crashes when talking to its own accessibility server
            let isTargetVimac = app.bundleIdentifier == Bundle.main.bundleIdentifier
            if isTargetVimac {
                return
            }
        }
        
        beforeModeActivation()
        
        Analytics.shared().track("Hint Mode Activated", properties: [
            "Target Application": app?.bundleIdentifier as Any
        ])
        
        modeController = HintModeController(app: app, window: window)
        modeController?.delegate = self
        modeController!.activate()
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
    
    // fun fact, focusedWindow need not return "AXWindow"...
    private func focusedWindow(app: NSRunningApplication) -> Element? {
        let axAppOptional = Application.init(app)
        guard let axApp = axAppOptional else { return nil }
        
        let axWindowOptional: UIElement? = try? axApp.attribute(.focusedWindow)
        guard let axWindow = axWindowOptional else { return nil }
        
        return Element.initialize(rawElement: axWindow.element)
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
