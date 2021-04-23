//
//  HoldKeyListener.swift
//  Vimac
//
//  Created by Dexter Leng on 22/4/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import os

enum HoldState: Equatable {
    case nothing
    case awaitingDelay
}

protocol HoldKeyListenerDelegate: AnyObject {
    func onKeyHeld(key: String)
}

class HoldKeyListener {
    let key = " "

    var state = HoldState.nothing

    var suppressedHintModeKeyDown: CGEvent?
    var suppressedScrollModeKeyDown: CGEvent?
    var timer: Timer?

    var eventTap: GlobalEventTap?
    weak var delegate: HoldKeyListenerDelegate?

    func start() {
        if eventTap == nil {
            let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
            eventTap = GlobalEventTap(eventMask: mask, onEvent: { [weak self] event -> CGEvent? in
                guard let self = self else { return event }
                
                let e = self.onEvent(event: event)
                
                if let e = e {
                    let nsEvent = NSEvent(cgEvent: e)!
                    self.log("transformed event. state=\(self.state) keyDown=\(nsEvent.type == .keyDown) characters=\(nsEvent.characters) modifiers=\(nsEvent.modifierFlags) isARepeat=\(nsEvent.isARepeat)")
                } else {
                    self.log("onEvent transformed to nil")
                }
                
                return e
            })
        }

        _ = eventTap?.enable()
    }

    func onEvent(event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else { return event }
        
        log("onEvent() called. state=\(self.state) keyDown=\(nsEvent.type == .keyDown) characters=\(nsEvent.characters) modifiers=\(nsEvent.modifierFlags) isARepeat=\(nsEvent.isARepeat)")

        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256
        if modifiersPresent {
            // its possible that a key down is Space and key up is Shift-Space
            // revert from postAction to nothing
            self.state = .nothing
            self.timer?.invalidate()
            self.timer = nil
            return event
        }

        guard let characters = nsEvent.characters else { return event }

        if state == .nothing  {
            if nsEvent.type == .keyDown && !nsEvent.isARepeat && characters == key {
                self.suppressedHintModeKeyDown = event
                setAwaitingKey(characters)
                return nil
            }
            return event
        }

        if case let .awaitingDelay = state {
            if nsEvent.type == .keyDown && nsEvent.isARepeat && characters == key {
                return nil
            }

            if nsEvent.type == .keyUp && characters == key {
                self.timer!.invalidate()
                self.timer = nil
                self.state = .nothing

                self.suppressedHintModeKeyDown!.post(tap: .cghidEventTap)
                let keyUp = suppressedHintModeKeyDown!.copy()!
                keyUp.type = .keyUp
                keyUp.post(tap: .cghidEventTap)

                return nil
            }

            if nsEvent.type == .keyDown && characters != key {
                self.timer!.invalidate()
                self.timer = nil
                self.state = .nothing

                self.suppressedHintModeKeyDown!.post(tap: .cghidEventTap)
                event.post(tap: .cghidEventTap)

                return nil
            }
            
            if nsEvent.type == .keyUp && characters != key {
                return event
            }

            return nil
        }

        fatalError("onEvent(): unhandled state \(state)")
    }

    func setAwaitingKey(_ key: String) {
        log("setAwaitingKey() called")
        if self.state != .nothing {
            fatalError("setAwaitingHintMode() called with invalid state \(state)")
        }

        self.state = .awaitingDelay
        self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(onAwaitingKeyTimeout), userInfo: nil, repeats: false)
    }

    @objc func onAwaitingKeyTimeout() {
        log("onAwaitingKeyTimeout() called")
        if state != .awaitingDelay {
            fatalError("onAwaitingKeyTimeout() called with invalid state \(state)")
        }

        self.timer = nil
        self.state = .nothing

        onKeyHeld()
    }

    func onKeyHeld() {
        log("onKeyHeld(): \(key)")
        self.delegate?.onKeyHeld(key: key)
    }
    
    func log(_ str: String) {
        os_log("%@", str)
    }
}
