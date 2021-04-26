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
import UserNotifications

class ModeCoordinator: ModeControllerDelegate {
    let disposeBag = DisposeBag()
    
    var priorKBLayout: InputSource?
    var forceKBLayout: InputSource?
    var forceKBLayoutObservation: NSKeyValueObservation?
    
    let scrollModeKeySequence: [Character] = ["j", "k"]
    let hintModeKeySequence: [Character] = ["f", "d"]
    private let keySequenceListener: VimacKeySequenceListener
    private var holdKeyListener: HoldKeyListener?
    
    var modeController: ModeController?
    
    init() {
        self.keySequenceListener = VimacKeySequenceListener()
        self.keySequenceListener.start()
        
        self.forceKBLayoutObservation = observeForceKBInputSource()
        
        disposeBag.insert(keySequenceListener.scrollMode.bind(onNext: { [weak self] _ in
            self?.setScrollMode(mechanism: "Key Sequence")
        }))
        
        disposeBag.insert(keySequenceListener.hintMode.bind(onNext: { [weak self] _ in
            self?.setHintMode(mechanism: "Key Sequence")
        }))
        
        UserDefaultsProperties.holdSpaceHintModeActivationEnabled.readLive()
            .bind(onNext: { [weak self] enabled in
                guard let self = self else { return }

                self.log("Hold Space to activate hint-mode enabled: \(enabled)")
                
                if let holdKeyListener = self.holdKeyListener {
                    holdKeyListener.stop()
                    self.holdKeyListener = nil
                }

                if enabled {
                    self.holdKeyListener = HoldKeyListener()
                    self.holdKeyListener?.delegate = self
                    self.holdKeyListener?.start()
                }
            })
            .disposed(by: disposeBag)
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
        
        let activationCount = UserDefaults.standard.integer(forKey: "hintModeActivationCount")
        let sentPMFSurvey = UserDefaults.standard.bool(forKey: "shownPMFSurveyAlert")
        if activationCount > 350 && !sentPMFSurvey {
            UserDefaults.standard.set(true, forKey: "shownPMFSurveyAlert")
            showPMFSurvey()
        }
    }

    func setScrollMode(mechanism: String) {
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
            "Target Application": frontmostApp.bundleIdentifier as Any,
            "Activation Mechanism": mechanism
        ])
        
        modeController = ScrollModeController(window: focusedWindow)
        modeController?.delegate = self
        modeController!.activate()
    }
    
    func setHintMode(mechanism: String) {
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
            "Target Application": app?.bundleIdentifier as Any,
            "Activation Mechanism": mechanism
        ])
        
        let activationCount = UserDefaults.standard.integer(forKey: "hintModeActivationCount")
        UserDefaults.standard.set(activationCount + 1, forKey: "hintModeActivationCount")
        
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
        
        // HACK: Chromium activates its accessibility feature when accessibilityRole is accessed
        let _: Any? = try? axApp.attribute( .role)
        
        let axWindowOptional: UIElement? = try? axApp.attribute(.focusedWindow)
        guard let axWindow = axWindowOptional else { return nil }
        
        return Element.initialize(rawElement: axWindow.element)
    }
    
    func showPMFSurvey() {
        Analytics.shared().track("PMF Survey Alert Shown")
        
        let alert = NSAlert()
        alert.messageText = "Congrats on hitting 350 activations! 🚀"
        alert.informativeText = "Mind sharing your experience using Vimac? Your feedback is valuable and will help us make Vimac even better."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes!")
        alert.addButton(withTitle: "No")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Analytics.shared().track("Opening PMF Survey")

            let url = URL(string: "https://vimacapp.com/pmf-survey?anon-id=\(Analytics.shared().getAnonymousId())")!
            _ = NSWorkspace.shared.open(url)
        } else {
            Analytics.shared().track("PMF Survey Alert Dismissed")
        }
    }
    
    func log(_ str: String) {
        os_log("%@", str)
    }
}

extension ModeCoordinator: HoldKeyListenerDelegate {
    func onKeyHeld(key: String) {
        if let modeController = self.modeController {
            if let _  = modeController as? HintModeController {
                self.deactivate()
                return
            }
        }

        self.setHintMode(mechanism: "Hold Space")
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
