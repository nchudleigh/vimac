//
//  HintModeState.swift
//  Vimac
//
//  Created by Dexter Leng on 15/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

protocol StateType {
    /// Events are effectful inputs from the outside world which the state reacts to, described by some
    /// data type. For instance: a button being clicked, or some network data arriving.
    associatedtype InputEvent

    /// Commands are effectful outputs which the state desires to have performed on the outside world.
    /// For instance: showing an alert, transitioning to some different UI, etc.
    associatedtype OutputCommand

    /// In response to an event, a state may transition to some new value, and it may emit a command.
    mutating func handleEvent(_ event: InputEvent) -> OutputCommand?

    // If you're not familiar with Swift, the mutation semantics here may seem like a very big red
    // flag, destroying the purity of this type. In fact, because states have *value semantics*,
    // mutation becomes mere syntax sugar. From a semantic perspective, any call to this method
    // creates a new instance of StateType; no code other than the caller has visibility to the
    // change; the normal perils of mutability do not apply.
    //
    // If this is confusing, keep in mind that we could equivalently define this as a function
    // which returns both a new state value and an optional OutputCommand (it just creates some
    // line noise later):
    //   func handleEvent(event: InputEvent) -> (Self, OutputCommand)

    /// State machines must specify an initial value.
    static var initialState: Self { get }

    // Traditional models often allow states to specific commands to be performed on entry or
    // exit. We could add that, or not.
}

enum HintModeState: StateType, Equatable {
    typealias InputEvent = Event
    typealias OutputCommand = Command
    
    case unactivated
    case activating
    case activated(hints: [Hint], input: String)
    case deactivated
    
    enum Event {
        case activate
        case deactivate
        case keyPress(event: NSEvent)
        case hintsFetched(hints: [Hint])
    }
    
    enum Command {
        case loadHints
        case drawHints
        case updateInput
        case rotateHints
        case perform(hint: Hint, action: HintAction)
        case eraseHints
    }
    
    static let initialState = Self.unactivated
    
    mutating func handleEvent(_ event: Event) -> OutputCommand? {
        switch (self, event) {
        case (.unactivated, .activate):
            self = .activating
            return .loadHints
        case (.activating, .hintsFetched(let hints)):
            self = .activated(hints: hints, input: "")
            return .drawHints
        case (.activated(let hints, let input), .keyPress(let event)):
            if event.type != .keyDown { return nil }
            if event.keyCode == kVK_Escape {
                self = .deactivated
                return .eraseHints
            }

            if event.keyCode == kVK_Delete {
                let newInput = input.dropLast()
                self = .activated(hints: hints, input: String(newInput))
                return .updateInput
            }
             if event.keyCode == kVK_Space {
                return .rotateHints
             }

             if let characters = event.charactersIgnoringModifiers {
                let newInput = input + characters
                let hintsWithInputAsPrefix = hints.filter { $0.text.starts(with: newInput.uppercased()) }

                if hintsWithInputAsPrefix.count == 0 {
                    self = .deactivated
                    return .eraseHints
                }
                
                let matchingHint = hintsWithInputAsPrefix.first(where: { $0.text == newInput.uppercased() })
                if let matchingHint = matchingHint {
                    let action: HintAction = {
                        if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                            return .rightClick
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                            return .doubleLeftClick
                        } else {
                            return .leftClick
                        }
                    }()
                    
                    self = .deactivated
                    return .perform(hint: matchingHint, action: action)
                }

                self = .activated(hints: hints, input: newInput)
                return .updateInput
             }
            return nil
        default:
            return nil
        }
    }
}
