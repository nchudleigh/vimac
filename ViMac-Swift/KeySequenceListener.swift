//
//  ListenForKeySequence.swift
//  Vimac
//
//  Created by Dexter Leng on 1/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxRelay

class KeySequenceListener {
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
    var eventTap: GlobalEventTap?
    private let inputState: InputState
    private var keyUps: [CGEvent] = []
    private var typed: [CGEvent] = []
    private var sequences: [[Character]] = []
    private var timer: Timer?
    private let resetDelay: TimeInterval
    
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
                guard let self = self else { return event }

                if let nsEvent = NSEvent(cgEvent: event) {
                    print("onEvent: characters:\(nsEvent.charactersIgnoringModifiers), keyUp?:\(event.type == .keyUp), repeat: \(nsEvent.isARepeat)")
                    
                    if !nsEvent.isARepeat {
                        return nil
                    }
                }
                
                return event
                
//                let e =  self.onEvent(event: event)
//
//                if  let e = e,
//                    let nsEvent = NSEvent(cgEvent: e) {
//                    print("onEvent transformed: characters:\(nsEvent.charactersIgnoringModifiers), keyUp?:\(event.type == .keyUp), repeat: \(nsEvent.isARepeat)")
//                } else {
//                    print("onEvent suppressed event")
//                }
//                return e
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
        
        print("onEvent: characters:\(nsEvent.charactersIgnoringModifiers), keyUp?:\(event.type == .keyUp), repeat: \(nsEvent.isARepeat)")
        
        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256
        if modifiersPresent {
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
        print("emitTyped() called")
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
        print("resetInput() called")
        
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
        print("setTimeout() called")
        
        self.timer = Timer.scheduledTimer(timeInterval: resetDelay, target: self, selector: #selector(onTimeout), userInfo: nil, repeats: false)
    }
}
