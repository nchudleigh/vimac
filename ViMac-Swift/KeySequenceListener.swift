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
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
    var eventTap: GlobalEventTap?
    private let inputState = InputState()
    private var typed: [CGEvent] = []
    private var sequences: [[Character]] = []
    private var timer: Timer?
    private let delayResetFreq: TimeInterval = 0.25
    
    private let matchRelay: PublishRelay<([Character])> = .init()
    lazy var matchEvents = matchRelay.asObservable()

    func registerSequence(seq: [Character]) throws -> Bool {
        let success = try inputState.addWord(seq)
        if !success {
            return false
        }
        sequences.append(seq)
        return true
    }
    
    func start() {
        if eventTap == nil {
            eventTap = GlobalEventTap(eventMask: mask, onEvent: { [weak self] event -> CGEvent? in
                guard let self = self else { return event}
                return self.onEvent(event: event)
            })
        }
        
        eventTap?.enable()
    }
    
    func stop() {
        eventTap?.disable()
    }
    
    private func onEvent(event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            reset()
            return event
        }
        
        let modifiersPresent = nsEvent.modifierFlags.rawValue != 256
        if modifiersPresent {
            reset()
            return event
        }

        guard let c = nsEvent.characters?.first else {
            reset()
            return event
        }
        
        if nsEvent.isARepeat {
            reset()
            return event
        }

        typed.append(event)
        try! inputState.advance(c)

        if inputState.state == .advancable {
            setTimeout()
            return nil
        } else if inputState.state == .matched {
            onMatch()
            reset()
            return nil
        } else if inputState.state == .deadend {
            // returning the event to the tap should be faster than emitting it.
            if typed.count == 1 {
                let e = typed.first!
                reset()
                return e
            }
            emitTyped()
            reset()
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
            keyDownEvent.post(tap: .cghidEventTap)
            
            let keyUpEvent = keyDownEvent.copy()!
            keyUpEvent.type = .keyUp
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }
    
    private func reset() {
        typed = []
        inputState.reset()
        timer?.invalidate()
    }
    
    @objc private func onTimeout() {
        emitTyped()
        reset()
    }
    
    private func setTimeout() {
        self.timer = Timer.scheduledTimer(timeInterval: delayResetFreq, target: self, selector: #selector(onTimeout), userInfo: nil, repeats: false)
    }
}
