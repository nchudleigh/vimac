//
//  ListenForKeySequence.swift
//  Vimac
//
//  Created by Dexter Leng on 1/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxRelay

enum HoldState: Equatable {
    case nothing
    case awaitingDelay(key: String)
    case postAction(key: String)
}

protocol HoldKeyListenerDelegate: AnyObject {
    func onKeyHeld(key: String)
}

class HoldKeyListener {
    let keys: [String]
    
    var state = HoldState.nothing
    
    var suppressedHintModeKeyDown: CGEvent?
    var suppressedScrollModeKeyDown: CGEvent?
    var timer: Timer?

    var eventTap: GlobalEventTap?
    weak var delegate: HoldKeyListenerDelegate?
    
    init(keys: [String]) {
        self.keys = keys
    }
        
    func start() {
        if eventTap == nil {
            let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
            eventTap = GlobalEventTap(eventMask: mask, onEvent: { [weak self] event -> CGEvent? in
                guard let self = self else { return event}
                return self.onEvent(event: event)
            })
        }
        
        _ = eventTap?.enable()
    }
    
    func onEvent(event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else { return event }
        
        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256
        if modifiersPresent { return event }

        guard let characters = nsEvent.characters else { return event }
        
        if state == .nothing  {
            if nsEvent.type == .keyDown && !nsEvent.isARepeat && keys.contains(characters) {
                self.suppressedHintModeKeyDown = event
                setAwaitingKey(characters)
                return nil
            }
            return event
        }
        
        if case let .postAction(key) = state {
            if nsEvent.type == .keyUp && characters == key {
                self.state = .nothing
                return nil
            }
            
            if nsEvent.type == .keyDown && nsEvent.isARepeat && characters == key {
                return nil
            }
            
            return nil
        }
        
        if case let .awaitingDelay(key) = state {
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
            
            return nil
        }
        
        fatalError("onEvent(): unhandled state \(state)")
    }
    
    func setAwaitingKey(_ key: String) {
        if self.timer != nil {
            fatalError("setAwaitingHintMode() called with self.timer != nil")
        }
        
        self.state = .awaitingDelay(key: key)
        self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(onAwaitingKeyTimeout), userInfo: nil, repeats: false)
    }
    
    @objc func onAwaitingKeyTimeout() {
        guard case let .awaitingDelay(key) = state else {
            fatalError("onAwaitingKeyTimeout() called with invalid state \(state)")
        }
        
        self.timer = nil
        self.state = .postAction(key: key)
        
        onKeyHeld(key: key)
    }
    
    func onKeyHeld(key: String) {
        print("onKeyHeld(): \(key)")
        self.delegate?.onKeyHeld(key: key)
    }
}

class KeySequenceListener {
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
    var eventTap: GlobalEventTap?
    private let inputState: InputState
    private var keyUps: [CGEvent] = []
    private var typed: [CGEvent] = []
    private var sequences: [[Character]] = []
    private var timer: Timer?
    private let resetDelay: TimeInterval
    private let typingDelay: TimeInterval = 0.5
    private var lastTypeDate: Date?
    
    private let matchRelay: PublishRelay<([Character])> = .init()
    lazy var matchEvents = matchRelay.asObservable()
    
    init?(sequences: [[Character]], resetDelay: TimeInterval = 0.25) {
        self.resetDelay = resetDelay
        self.inputState = InputState()
        self.sequences = sequences
        
        var registeredSequences = 0
        for seq in sequences {
            let success = try! registerSequence(seq: seq)
            if success {
                registeredSequences += 1
            }
        }
        
        if registeredSequences == 0 {
            return nil
        }
    }

    private func registerSequence(seq: [Character]) throws -> Bool {
        let success = try inputState.addWord(seq)
        if !success {
            return false
        }
        sequences.append(seq)
        return true
    }
    
    func started() -> Bool {
        guard let eventTap = eventTap else { return false }
        return eventTap.enabled()
    }
    
    func start() {
        if eventTap == nil {
            eventTap = GlobalEventTap(eventMask: mask, onEvent: { [weak self] event -> CGEvent? in
                guard let self = self else { return event}
                return self.onEvent(event: event)
            })
        }
        
        _ = eventTap?.enable()
    }
    
    func stop() {
        eventTap?.disable()
        eventTap = nil
    }
    
    private func onEvent(event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            resetInput()
            return event
        }
        
        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256
        if modifiersPresent {
            self.lastTypeDate = Date()
            
            resetInput()
            return event
        }

        guard let c = nsEvent.characters?.first else {
            resetInput()
            return event
        }
        
        if nsEvent.isARepeat {
            resetInput()
            return event
        }
        
        if event.type == .keyUp {
            keyUps.append(event)
            return event
        }
        
        if let lastTypeDate = lastTypeDate {
            if Date() < lastTypeDate.addingTimeInterval(self.typingDelay) {
                self.lastTypeDate = Date()
                return event
            }
        }

        typed.append(event)
        try! inputState.advance(c)

        if inputState.state == .advancable {
            setTimeout()
            return nil
        } else if inputState.state == .matched {
            onMatch()
            resetInput()
            return nil
        } else if inputState.state == .deadend {
            self.lastTypeDate = Date()
            
            // returning the event to the tap should be faster than emitting it.
            if typed.count == 1 {
                let e = typed.first!
                resetInput()
                return e
            }
            emitTyped()
            resetInput()
            return nil
        } else {
            fatalError()
        }
    }
    
    private func onMatch() {
        let sequence = try! inputState.matchedWord()
        matchRelay.accept(sequence)
    }
    
    private func emitTyped() {
        for keyDownEvent in typed {
            guard let nsEvent = NSEvent(cgEvent: keyDownEvent) else { continue }

            keyDownEvent.post(tap: .cghidEventTap)
            
            let associatedKeyEvent = keyUps.first(where: { keyUp in
                if let e = NSEvent(cgEvent: keyUp) {
                    if e.charactersIgnoringModifiers == nsEvent.charactersIgnoringModifiers {
                        return true
                    }
                }
                return false
            })
            if let associatedKeyEvent = associatedKeyEvent {
                associatedKeyEvent.post(tap: .cghidEventTap)
            }
        }
    }
    
    private func resetInput() {
        typed = []
        keyUps = []
        inputState.resetInput()
        timer?.invalidate()
    }
    
    @objc private func onTimeout() {
        emitTyped()
        resetInput()
    }
    
    private func setTimeout() {
        self.timer = Timer.scheduledTimer(timeInterval: resetDelay, target: self, selector: #selector(onTimeout), userInfo: nil, repeats: false)
    }
}
