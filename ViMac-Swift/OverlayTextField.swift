//
//  OverlayTextField.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class OverlayTextField: NSTextField {
    var cursorAction: CursorAction?
    weak var overlayTextFieldDelegate: OverlayTextFieldDelegate?
    var isFirstResponderSubject: BehaviorSubject<Bool>?
    var keyEventObservable: Observable<KeyAction>?
    var keyEventObservableDistinct: Observable<KeyAction>?
    

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    func setup() {
        self.isFirstResponderSubject = BehaviorSubject(value: false)
        self.keyEventObservable = OverlayTextField.getKeyEventObservable(isFirstResponderSubject: isFirstResponderSubject!).share()
        self.keyEventObservableDistinct = keyEventObservable!
            .distinctUntilChanged({ (k1, k2) -> Bool in
                return k1.keyPosition == k2.keyPosition && k1.character == k2.character
            }).share()
    }

    override func becomeFirstResponder() -> Bool {
        let responderStatus = super.becomeFirstResponder();
        self.isFirstResponderSubject?.onNext(true)
        
        // default behaviour causes all text to be selected, so when the user types all text is erased
        // this fixes the behaviour
        // https://stackoverflow.com/a/32380549/10390454
        let selectionRange = self.currentEditor()!.selectedRange
        self.currentEditor()?.selectedRange = NSMakeRange(selectionRange.length, 0);
        return responderStatus;
    }
    
    override func resignFirstResponder() -> Bool {
        self.isFirstResponderSubject!.onNext(false)
        let result = super.resignFirstResponder()
        return result
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.overlayTextFieldDelegate?.onEscape()
    }
    
    func observeCharacterEvent(character: Character) -> Observable<KeyAction> {
        return self.keyEventObservableDistinct!
            .filter({ $0.character == character })
    }
    
    static func getKeyEventObservable(isFirstResponderSubject: BehaviorSubject<Bool>) -> Observable<KeyAction> {
        return isFirstResponderSubject
            .flatMapLatest({ isFirstResponder -> Observable<KeyAction?> in
                if !isFirstResponder {
                    return Observable.just(nil)
                }
                
                return Observable.create({ observer in
                    let keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event -> NSEvent? in
                        let characters = event.characters
                        guard let typedCharacter: Character = characters?.first else {
                            return event
                        }
                        let keyAction = KeyAction(keyPosition: .keyDown, character: typedCharacter)
                        observer.onNext(keyAction)
                        return event
                    })
                    
                    let keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: { event -> NSEvent? in
                        let characters = event.characters
                        guard let typedCharacter: Character = characters?.first else {
                            return event
                        }
                        let keyAction = KeyAction(keyPosition: .keyUp, character: typedCharacter)
                        observer.onNext(keyAction)
                        return event
                    })
                    
                    let cancel = Disposables.create {
                        NSEvent.removeMonitor(keyDownMonitor)
                        NSEvent.removeMonitor(keyUpMonitor)
                    }
                    return cancel
                })
            })
            .compactMap({ $0 })
    }
    
    func getDistinctKeyEventObservable() {
        
    }
}

protocol OverlayTextFieldDelegate: AnyObject {
    func onEscape() -> Void
}
