//
//  NSEvent.swift
//  Vimac
//
//  Created by Dexter Leng on 5/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

extension NSEvent {
    static func localEventMonitor() -> Observable<NSEvent> {
        Observable.create({ observer in
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
    }
}
