//
//  ScrollModeInputState.swift
//  Vimac
//
//  Created by Dexter Leng on 23/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class ScrollModeInputState {
    private let inputState = InputState()
    private var bindings: [ScrollKeyConfig.Binding] = []
    
    enum AdvanceStatus {
        case match(scrollDirection: ScrollDirection)
        case deadend
        case advancable
    }
    
    func registerBinding(binding: ScrollKeyConfig.Binding) throws -> Bool {
        let success = try inputState.addWord(binding.keys)
        if !success {
            return false
        }
        bindings.append(binding)
        return true
    }
    
    func advance(key: Character) throws -> AdvanceStatus {
        try inputState.advance(key)

        switch inputState.state {
        case .matched:
            let matchedKeys = try inputState.matchedWord()
            let direction = mapKeysToScrollDirection(keys: matchedKeys)
            return .match(scrollDirection: direction)
        case .deadend:
            return .deadend
        case .advancable:
            return .advancable
        default:
            fatalError()
        }
        
    }
    
    private func mapKeysToScrollDirection(keys: [Character]) -> ScrollDirection {
        for binding in bindings {
            if binding.keys == keys {
                return binding.direction
            }
        }
        fatalError()
    }
}
