//  ViMac-Swift
//
//  Created by Dexter Leng on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import MASShortcut
import RxSwift

class Utils: NSObject {
    static let forceKeyboardLayoutKey = "ForceKeyboardLayout"
    static let shouldLaunchOnStartupKey = "ShouldLaunchOnStartupKey"
    
    static func registerDefaults() {
        KeyboardShortcuts.shared.registerDefaults()
        
        UserDefaults.standard.register(defaults: [
            Utils.shouldLaunchOnStartupKey: false,
        ])
    }
    
    static func moveMouse(position: CGPoint) {
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    static func leftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        // for some reason you need to do this for some application to recognize the click
        // see: https://stackoverflow.com/a/2420366/10390454
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event2?.setIntegerValueField(.mouseEventClickState, value: 1)
        // explicitly set flags because clicking while holding a modifier key can alter it's behaviour
        // e.g. CTRL + left click -> right click,
        // Shift + right click -> Nothing in Finder
        // this matters because modifier keys are used to trigger different click types in Hint Mode.
        event?.flags = .init()
        event2?.flags = .init()
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    static func doubleLeftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event?.flags = .init()
        
        event?.post(tap: .cghidEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cghidEventTap)
        
        event?.setIntegerValueField(.mouseEventClickState, value: 2)
        
        event?.type = .leftMouseDown
        event?.post(tap: .cghidEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cghidEventTap)
    }
    
    static func rightClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: position, mouseButton: .right)
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event?.flags = .init()
        
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: position, mouseButton: .right)
        event2?.setIntegerValueField(.mouseEventClickState, value: 1)
        event2?.flags = .init()
        
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    // eagerConcat behaves like concat but all the observables are fired simultaneously instead of only after the previous ones are completed.
    static func eagerConcat<T>(observables: [Observable<T>]) -> Observable<T> {
        let taggedWithIndex = observables.enumerated().map({ (index, element) in
            return element.map({ (index, $0) })
        })
        let merged = Observable.merge(taggedWithIndex).toArray().asObservable()

        return merged.flatMapLatest({ o -> Observable<T> in
            let sortedO = o
                .sorted(by: { (a, b) in
                    let (i1, _) = a
                    let (i2, _) = b
                    return i1 - i2 < 0
                })
                .map({ (i, e) in e })
            return Observable.from(sortedO)
        })
    }

    // For performance reasons Chromium only makes the webview accessible when there it detects voiceover through the `AXEnhancedUserInterface` attribute on the Chrome application itself:
    // http://dev.chromium.org/developers/design-documents/accessibility
    // Similarly, electron uses `AXManualAccessibility`:
    // https://electronjs.org/docs/tutorial/accessibility#assistive-technology
    // AXEnhancedUserInterface breaks window managers, so it's removed for now.
    static func setAccessibilityAttributes(app: NSRunningApplication) {
//        do {
//            try app.setAttribute("AXEnhancedUserInterface", value: true)
//        } catch {
//
//        }
        
        _ = try? Application(app)?.setAttribute("AXManualAccessibility", value: true)
    }
    
    static func singleToObservable<T>(single: Single<[T]>) -> Observable<T> {
        return single.asObservable()
            .flatMap({ elements in
                return Observable.from(elements)
            })
    }
}
