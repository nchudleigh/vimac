//
//  HoldKeyListener.swift
//  Vimac
//
//  Created by Dexter Leng on 22/4/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

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
                
                return self.onEvent(event: event)
            })
        }

        _ = eventTap?.enable()
    }
    
    func stop() {
        eventTap?.disable()
        eventTap = nil
    }

    func onEvent(event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else { return event }

        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256

        guard let characters = nsEvent.charactersIgnoringModifiers else { return event }
        
        if state == .nothing  {
            if nsEvent.type == .keyDown && !nsEvent.isARepeat && characters == key && !modifiersPresent {
                self.suppressedHintModeKeyDown = event
                setAwaitingKey(characters)
                return nil
            }
            return event
        }

        if case let .awaitingDelay = state {
            if nsEvent.type == .keyDown && nsEvent.isARepeat && characters == key && !modifiersPresent {
                return nil
            }

            // notice the lack of modifier check.
            // its possible that a key down is Space and key up is Shift-Space
            // since we suppressed the original key down, we need to emit it here
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
        if self.state != .nothing {
            fatalError("setAwaitingHintMode() called with invalid state \(state)")
        }

        self.state = .awaitingDelay
        self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(onAwaitingKeyTimeout), userInfo: nil, repeats: false)
    }

    @objc func onAwaitingKeyTimeout() {
        if state != .awaitingDelay {
            fatalError("onAwaitingKeyTimeout() called with invalid state \(state)")
        }

        self.timer = nil
        self.state = .nothing

        onKeyHeld()
    }

    func onKeyHeld() {
        self.delegate?.onKeyHeld(key: key)
    }
}
