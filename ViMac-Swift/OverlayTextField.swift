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
    weak var overlayTextFieldDelegate: OverlayTextFieldDelegate?
    let isFirstResponderSubject: BehaviorSubject<Bool>
    let nsEventObservable: Observable<NSEvent>
    let distinctNSEventObservable: Observable<NSEvent>
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init(frame frameRect: NSRect) {
        self.isFirstResponderSubject = BehaviorSubject(value: false)
        self.nsEventObservable = OverlayTextField
            .getNSEventObservable(isFirstResponderSubject: isFirstResponderSubject)

        
        self.distinctNSEventObservable = nsEventObservable
            .distinctUntilChanged({ (k1, k2) -> Bool in
                return k1.type == k2.type && k1.characters == k2.characters
            })
            .share()
        super.init(frame: frameRect)
    }

    override func becomeFirstResponder() -> Bool {
        let responderStatus = super.becomeFirstResponder();
        self.isFirstResponderSubject.onNext(true)
        
        // default behaviour causes all text to be selected, so when the user types all text is erased
        // this fixes the behaviour
        // https://stackoverflow.com/a/32380549/10390454
        //let selectionRange = self.currentEditor()!.selectedRange
        //self.currentEditor()?.selectedRange = NSMakeRange(selectionRange.length, 0);
        return responderStatus;
    }
    
    override func resignFirstResponder() -> Bool {
        self.isFirstResponderSubject.onNext(false)
        let result = super.resignFirstResponder()
        return result
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.overlayTextFieldDelegate?.onEscape()
    }

    static func getNSEventObservable(isFirstResponderSubject: BehaviorSubject<Bool>) -> Observable<NSEvent> {
        return isFirstResponderSubject
            .flatMapLatest({ isFirstResponder -> Observable<NSEvent> in
                if !isFirstResponder {
                    return Observable.empty()
                }
                
                return Observable.create({ observer in
                    let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown.union(.keyUp), handler: { event -> NSEvent? in
                        observer.onNext(event)
                        // return nil to prevent the event from being dispatched
                        // this removes the "doot doot" sound when typing with CMD / CTRL held down
                        return nil
                    })
                    
                    let cancel = Disposables.create {
                        NSEvent.removeMonitor(keyMonitor)
                    }
                    return cancel
                })
            })
    }
}

protocol OverlayTextFieldDelegate: AnyObject {
    func onEscape() -> Void
}
