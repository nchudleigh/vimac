import Cocoa
import RxSwift

struct ScrollKeyConfig {
    struct Binding {
        let key: Character
        let direction: ScrollDirection
        let modifiers: NSEvent.ModifierFlags?
    }
    
    let bindings: [Binding]
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

class ScrollModeInputListener: InputListener {
    struct ScrollEvent: Equatable {
        let direction: ScrollDirection
        let state: ScrollState
    }

    private let disposeBag = DisposeBag()
    private let scrollKeyConfig: ScrollKeyConfig
    
    let scrollEventSubject: PublishSubject<ScrollEvent> = PublishSubject()
    
    init(scrollKeyConfig: ScrollKeyConfig) {
        print("scroll mode listener initialized")
        self.scrollKeyConfig = scrollKeyConfig
        super.init()

        disposeBag.insert(observeScrollEvent(bindings: scrollKeyConfig.bindings))
    }
    
    deinit {
        print("scroll mode listener deinitialized")
    }
    
    func onScrollEvent(event: ScrollEvent) {
        scrollEventSubject.onNext(event)
    }
    
    func observeScrollEvent(bindings: [ScrollKeyConfig.Binding]) -> Disposable {
        let scrollEventObservables = bindings.map({ [weak self] b in self!.scrollEvent(binding: b) })
        let observable = Observable.merge(scrollEventObservables)
        return observable.bind(onNext: { [weak self] event in
            self?.onScrollEvent(event: event)
        })
    }
    
    func scrollEvent(binding: ScrollKeyConfig.Binding) -> Observable<ScrollEvent> {
        return events(character: binding.key, modifierFlags: binding.modifiers)
            .map({ event -> ScrollEvent in
                if event.type == .keyDown {
                    return ScrollEvent(direction: binding.direction, state: .start)
                } else if event.type == .keyUp {
                    return ScrollEvent(direction: binding.direction, state: .stop)
                } else {
                    fatalError("An unexpected non-keyDown/keyUp event was received.")
                }
            })
            // keyDown events are repeatedly fired when the key is held down.
            // this prevents sequential events of the same direction and state from being emitted.
            .distinctUntilChanged()
    }

    func events(character: Character, modifierFlags: NSEvent.ModifierFlags?) -> Observable<NSEvent> {
        return events
            .filter({ [weak self] event in
                return self!.doesEventMatchCharacter(event: event, character: character)
            })
            .filter({ [weak self] event in
                return
                    self!.doesEventMatchCharacter(event: event, character: character) &&
                        event.modifierFlags.intersection(.deviceIndependentFlagsMask) == (modifierFlags ?? .init())
            })
    }
    
    
    
    func doesEventMatchBinding(event: NSEvent, binding: ScrollKeyConfig.Binding) -> Bool {
        return
            doesEventMatchCharacter(event: event, character: binding.key) &&
            doesEventMatchModifiers(event: event, modifiers: binding.modifiers)
    }
    
    func doesEventMatchCharacter(event: NSEvent, character: Character) -> Bool {
        return event.characters == String(character)
    }
    
    func doesEventMatchModifiers(event: NSEvent, modifiers: NSEvent.ModifierFlags?) -> Bool {
        return event.modifierFlags.intersection(.deviceIndependentFlagsMask) ==
            (
                modifiers ??
                // 256 is the rawValue when there are no modifiers
                NSEvent.ModifierFlags.init(rawValue: 256)
            )
    }
}
