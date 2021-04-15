import Cocoa
import RxSwift

struct ScrollKeyConfig {
    struct Binding {
        let keys: [Character]
        let direction: ScrollDirection
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
    case top
    case bottom
}

enum ScrollState {
    case start
    case stop
}

class ScrollModeInputListener {
    struct ScrollEvent: Equatable {
        let direction: ScrollDirection
        let state: ScrollState
    }

    private let disposeBag = DisposeBag()
    private let scrollKeyConfig: ScrollKeyConfig
    
    private let inputListener: InputListener
    
    let scrollEventSubject: PublishSubject<ScrollEvent> = PublishSubject()
    let escapeEventSubject: PublishSubject<Void> = PublishSubject()
    let controlLeftBracketEventSubject: PublishSubject<Void> = PublishSubject()
    let tabEventSubject: PublishSubject<Void> = PublishSubject()
    
    init(scrollKeyConfig: ScrollKeyConfig, inputListener: InputListener) {
        self.scrollKeyConfig = scrollKeyConfig
        self.inputListener = inputListener

        disposeBag.insert(observeScrollEvent(bindings: scrollKeyConfig.bindings))
        disposeBag.insert(observeEscapeKey())
        disposeBag.insert(observeControlLeftBracketKeyCombo())
        disposeBag.insert(observeTabKey())
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
    
    func observeEscapeKey() -> Disposable {
        let escapeEvents = events().filter({ event in
            event.keyCode == kVK_Escape && event.type == .keyDown
        })
        return escapeEvents.bind(onNext: { [weak self] _ in
            self!.escapeEventSubject.onNext(())
        })
    }
    
    func observeControlLeftBracketKeyCombo() -> Disposable {
        let controlLeftBracketEvents = events().filter({ event in
            event.keyCode == kVK_ANSI_LeftBracket &&
                event.type == .keyDown &&
                event.modifierFlags.rawValue & NSEvent.ModifierFlags.control.rawValue == NSEvent.ModifierFlags.control.rawValue
        })
        return controlLeftBracketEvents.bind(onNext: { [weak self] _ in
            self!.controlLeftBracketEventSubject.onNext(())
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
            // keyDown events are repeatedly fired when the key is held down.
            // this prevents sequential events of the same direction and state from being emitted.
            .distinctUntilChanged()
    }
    
    static func doesEventMatchBinding(event: NSEvent, binding: ScrollKeyConfig.Binding) -> Bool {
        return event.characters == String(binding.keys)
    }
    
    private func events() -> Observable<NSEvent> {
        return inputListener.events
    }
}
