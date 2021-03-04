//
//  HintModeInputEvent.swift
//  Vimac
//
//  Created by Dexter Leng on 5/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

enum HintModeInputIntent {
    case rotate
    case exit
    case backspace
    case advance(characters: String, action: HintAction)
    
    static func fromInputMonitor(_ monitor: Observable<NSEvent> = NSEvent.localEventMonitor()) -> Observable<HintModeInputIntent> {
        monitor
            .map { event in
                if event.type != .keyDown { return nil }
                if event.keyCode == kVK_Escape { return .exit }
                if event.keyCode == kVK_Delete { return .backspace }
                if event.keyCode == kVK_Space { return .rotate }

                if let characters = event.charactersIgnoringModifiers {
                    let action: HintAction = {
                        if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                            return .rightClick
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                            return .doubleLeftClick
                        } else {
                            return .leftClick
                        }
                    }()
                    return .advance(characters: characters, action: action)
                }

                return nil
            }
            .compactMap({ $0 })
    }
}

