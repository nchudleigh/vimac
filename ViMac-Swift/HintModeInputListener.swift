//
//  HintModeInputListener.swift
//  Vimac
//
//  Created by Dexter Leng on 23/8/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

struct ComposeTransformer<T, R> {
    let transformer: (Observable<T>) -> Observable<R>
    init(transformer: @escaping (Observable<T>) -> Observable<R>) {
        self.transformer = transformer
    }
    
    func call(_ observable: Observable<T>) -> Observable<R> {
        return transformer(observable)
    }
}

extension ObservableType {
    func compose<T>(_ transformer: ComposeTransformer<Element, T>) -> Observable<T> {
        return transformer.call(self.asObservable())
    }
}

enum HintModeUserEvent {
    case spaceKeyDown
    case escapeKeyDown
    case deleteKeyDown
    case keyDown(_ characters: String)
}

enum HintModeAction {
    case exit
    // active
    case rotateHints
    case advance(_ characters: String)
    case backspace
    // init
    case fetchHints
    // loading
    case setHints(_ hints: [Hint])
}

let localInputMonitor: Observable<NSEvent> = Observable.create({ observer in
    let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown.union(.keyUp), handler: { event -> NSEvent? in
        observer.onNext(event)
        // return nil to prevent the event from being dispatched
        // this removes the "doot doot" sound when typing with CMD / CTRL held down
        return nil
    })!
    
    let cancel = Disposables.create {
        NSEvent.removeMonitor(keyMonitor)
    }
    return cancel
})

let hintModeUserEvents = ComposeTransformer<NSEvent, HintModeUserEvent> { nsEvents in
    return nsEvents
        .map { event in
            if event.type != .keyDown { return nil }
            if event.keyCode == kVK_Escape { return .escapeKeyDown }
            if event.keyCode == kVK_Delete { return .deleteKeyDown }
            if event.keyCode == kVK_Space { return .spaceKeyDown }
            
            if let characters = event.characters { return .keyDown(characters) }
            
            return nil
        }
        .compactMap({ $0 })
}

let hintModeActions = ComposeTransformer<HintModeUserEvent, HintModeAction> { userEvents in
    return userEvents.map { event in
        switch event {
        case .spaceKeyDown:
            return .rotateHints
        case.deleteKeyDown:
            return .backspace
        case .escapeKeyDown:
            return .exit
        case .keyDown(let characters):
            return .advance(characters)
        }
    }
}

enum HintModeState {
    struct Context {
        let originalMousePosition: NSPoint
        let startTime: CFAbsoluteTime
    }

    struct ActiveContext {
        let hints: [Hint]
        let typed: String
        
        func possibleHints() -> [Hint] {
            hints.filter { $0.text.hasPrefix(typed) }
        }
        
        func typedHint() -> Hint? {
            possibleHints().first(where: { $0.text == typed })
        }
        
        func advance(characters: String) -> ActiveContext {
            ActiveContext(hints: hints, typed: typed + characters)
        }
    }
    
    case initial(ctx: Context)
    case loading(ctx: Context)
    case active(activeCtx: ActiveContext, ctx: Context)
    case error(ctx: Context)
}

struct Hint {
    let text: String
    let element: Element
}

func hintModeState(hints: [Hint], actions: Observable<HintModeAction>) -> Observable<HintModeState>{
    let initialState = HintModeState(hints: hints, typed: "")
    return actions.scan(initialState, accumulator: { (state, action) -> HintModeState in
        switch action {
        case .exit:
            // ??
            return state
        case .advance(let characters):
            return state.advance(characters: characters)
        default:
            return state
        }
    })
}

class HintModeInputListener {
    private let disposeBag = DisposeBag()
    private let inputListener = InputListener()
    
    func observeEscapeKey(onEvent: @escaping (NSEvent) -> ()) {
        let escapeEvents = events().filter({ event in
            event.keyCode == kVK_Escape && event.type == .keyDown
        })
        let disposable = escapeEvents.bind(onNext: { event in
            onEvent(event)
        })
        disposeBag.insert(disposable)
    }
    
    func observeKeyDown(onEvent: @escaping (NSEvent) -> ()) {
        let keyDownObservable = events()
            .filter({ event in
                if event.charactersIgnoringModifiers == nil {
                    return false
                }
                return event.type == .keyDown &&
                     event.keyCode != kVK_Delete &&
                     event.keyCode != kVK_Space &&
                    event.keyCode != kVK_Escape
            })
        let disposable = keyDownObservable.bind(onNext: { event in
            onEvent(event)
        })
        disposeBag.insert(disposable)
    }
    
    func observeDeleteKey(onEvent: @escaping (NSEvent) -> ()) {
        let deleteKeyDownObservable = events().filter({ event in
            return event.keyCode == kVK_Delete && event.type == .keyDown
        })
        let disposable = deleteKeyDownObservable.bind(onNext: { event in
            onEvent(event)
        })
        disposeBag.insert(disposable)
    }

    func observeSpaceKey(onEvent: @escaping (NSEvent) -> ()) {
        let spaceKeyDownObservable = events().filter({ event in
            return event.keyCode == kVK_Space && event.type == .keyDown
        })
        let disposable = spaceKeyDownObservable.bind(onNext: { event in
            onEvent(event)
        })
        disposeBag.insert(disposable)
    }
    
    private func events() -> Observable<NSEvent> {
        return inputListener.events
    }
}
