//
//  KeyboardShortcuts.swift
//  Vimac
//
//  Created by Dexter Leng on 27/2/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts.init()
    
    let hintModeShortcutKey = "HintModeShortcut"
    let scrollModeShortcutKey = "ScrollModeShortcut"
    let defaultHintShortcut = MASShortcut.init(keyCode: kVK_ANSI_F, modifierFlags: [.control])
    let defaultScrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_J, modifierFlags: [.control])
    
    func registerDefaults() {
        let hintModeTempView = MASShortcutView.init()
        hintModeTempView.associatedUserDefaultsKey = self.hintModeShortcutKey
        if hintModeTempView.shortcutValue == nil {
            hintModeTempView.shortcutValue = self.defaultHintShortcut
        }
        
        let scrollModeTempView = MASShortcutView.init()
        scrollModeTempView.associatedUserDefaultsKey = self.scrollModeShortcutKey
        if scrollModeTempView.shortcutValue == nil {
            scrollModeTempView.shortcutValue = self.defaultScrollShortcut
        }
    }

    func hintModeShortcutActivation() -> Observable<Void> {
        Observable.create { observer in
            MASShortcutBinder.shared()
                .bindShortcut(withDefaultsKey: self.hintModeShortcutKey, toAction: {
                    observer.onNext(Void())
                })
            return Disposables.create()
        }
    }
    
    func scrollModeShortcutActivation() -> Observable<Void> {
        Observable.create { observer in
            MASShortcutBinder.shared()
                .bindShortcut(withDefaultsKey: self.scrollModeShortcutKey, toAction: {
                    observer.onNext(Void())
                })
            return Disposables.create()
        }
    }
}
