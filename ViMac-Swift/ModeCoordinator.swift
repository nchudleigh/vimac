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
    let disposeBag = DisposeBag()
    
    var priorKBLayout: InputSource?
    var forceKBLayout: InputSource?
    var forceKBLayoutObservation: NSKeyValueObservation?
    
    let scrollModeKeySequence: [Character] = ["j", "k"]
    let hintModeKeySequence: [Character] = ["f", "d"]
    private let keySequenceListener: VimacKeySequenceListener
    
    var windowController: OverlayWindowController
    
    init(windowController: OverlayWindowController) {
        self.windowController = windowController

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
        
        keySequenceListener.start()
    }
    
    func setViewController(vc: ModeViewController) {
        vc.modeCoordinator = self
        self.windowController.window?.contentViewController = vc
        self.windowController.fitScreen()
        self.windowController.showWindow(nil)
        self.windowController.window?.makeKeyAndOrderFront(nil)
    }

    func setScrollMode() {
        self.priorKBLayout = InputSourceManager.currentInputSource()
        if let forceKBLayout = self.forceKBLayout {
            forceKBLayout.select()
        }
        
        let vc = ScrollModeViewController.init()
        self.setViewController(vc: vc)
        
        keySequenceListener.stop()
    }
    
    func setHintMode() {
        guard let applicationWindow = Utils.getCurrentApplicationWindowManually(),
            let window = self.windowController.window else {
            self.exitMode()
            return
        }
        
        self.priorKBLayout = InputSourceManager.currentInputSource()
        if let forceKBLayout = self.forceKBLayout {
            forceKBLayout.select()
        }

        let vc = HintModeViewController.init(applicationWindow: applicationWindow)
        self.setViewController(vc: vc)
        
        keySequenceListener.stop()
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
