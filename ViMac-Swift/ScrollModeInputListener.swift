import Cocoa
import RxSwift

struct ScrollKeyConfig {
    struct Binding {
        let keys: String
        let direction: ScrollDirection
    }
    
    let bindings: [Binding]
    
    func mapKeysToBinding(keys: String) -> Binding? {
        for binding in bindings {
            if binding.keys == keys {
                return binding
            }
        }
        return nil
    }
}

enum ScrollDirection {
    case left
    case down
    case up
    case right
    case halfLeft
    case halfDown
    case halfUp
    case halfRight
    case scrollToTop
    case scrollToBottom
}

enum ScrollState {
    case start
    case stop
}

class ScrollModeInputListenerFactory {
    static func instantiate() -> ScrollModeInputListener {
        let config = UserPreferences.ScrollMode.ScrollKeysProperty.readAsConfig()
        return ScrollModeInputListener(scrollKeyConfig: config)
    }
}

class ScrollModeInputListener {
    struct ScrollEvent: Equatable {
        let direction: ScrollDirection
        let state: ScrollState
    }

    private let disposeBag = DisposeBag()
    private let scrollKeyConfig: ScrollKeyConfig
    
    private let inputListener = InputListener()
    private let inputState: InputState
    
    let scrollEventSubject: PublishSubject<ScrollEvent> = PublishSubject()
    let escapeEventSubject: PublishSubject<Void> = PublishSubject()
    let tabEventSubject: PublishSubject<Void> = PublishSubject()
    
    init(scrollKeyConfig: ScrollKeyConfig) {
        self.scrollKeyConfig = scrollKeyConfig
        
        let keyBindings = scrollKeyConfig.bindings.map { Array($0.keys) }
        self.inputState = InputState(keySequences: keyBindings, commonPrefixDelaySeconds: 0.5)
        
        self.inputState.registerListener({ [weak self] keys in
            self?.onTypedBinding(keys: String(keys))
        })

        disposeBag.insert(observeEscapeKey())
        disposeBag.insert(observeTabKey())
        disposeBag.insert(observeKeyDown())
    }
    
    func onTypedBinding(keys: String) {
        guard let binding = scrollKeyConfig.mapKeysToBinding(keys: keys) else {
            fatalError("keys emitted from InputState does not match a binding")
        }
        
        self.
        self.onScrollEvent(event: <#T##ScrollModeInputListener.ScrollEvent#>)
    }
    
    func onScrollEvent(event: ScrollEvent) {
        scrollEventSubject.onNext(event)
    }
    
    func observeKeyDown() -> Disposable {
        let keyDownObservable = events()
            .filter({ event in
                if event.charactersIgnoringModifiers == nil {
                    return false
                }
                return event.type == .keyDown
            })
        return keyDownObservable.bind(onNext: { [weak self] event in
            self?.onKeyDown(event: event)
        })
    }
    
    func onKeyDown(event: NSEvent) {
        if let c = event.characters?.first {
          inputState.advance(c)
        }
    }
    
    func observeScrollEvent(bindings: [ScrollKeyConfig.Binding]) -> Disposable {
        let scrollEventObservables = bindings.map({ [weak self] b in self!.scrollEvent(binding: b) })
        let observable = Observable.merge(scrollEventObservables)
        return observable.bind(onNext: { [weak self] event in
            self?.onScrollEvent(event: event)
        })
    }
    
    func observeEscapeKey() -> Disposable {
        let escapeEvents = events().filter({ event in
            event.keyCode == kVK_Escape && event.type == .keyDown
        })
        return escapeEvents.bind(onNext: { [weak self] _ in
            self!.escapeEventSubject.onNext(())
        })
    }
    
    func observeTabKey() -> Disposable {
        let tabEvents = events().filter({ event in
            event.keyCode == kVK_Tab && event.type == .keyDown
        })
        return tabEvents.bind(onNext: { [weak self] _ in
            self!.tabEventSubject.onNext(())
        })
    }
    
    func scrollEvent(binding: ScrollKeyConfig.Binding) -> Observable<ScrollEvent> {
        return events()
            .filter({ event in
                return ScrollModeInputListener.doesEventMatchBinding(event: event, binding: binding)
            })
            .map({ event -> ScrollEvent in
                if event.type == .keyDown {
                    return ScrollEvent(direction: binding.direction, state: .start)
                } else if event.type == .keyUp {
                    return ScrollEvent(direction: binding.direction, state: .stop)
                } else {
                    fatalError("An unexpected non-keyDown/keyUp event was received.")
                }
            })
    }
    
    func bindingToScrollEvent()
    
    static func doesEventMatchBinding(event: NSEvent, binding: ScrollKeyConfig.Binding) -> Bool {
        return event.characters == binding.keys
    }
    
    private func events() -> Observable<NSEvent> {
        return inputListener.nonRepeatEvents
    }
}
