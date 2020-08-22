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
