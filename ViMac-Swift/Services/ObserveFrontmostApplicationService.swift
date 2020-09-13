//
//  ObserveFrontmostApplicationService.swift
//  Vimac
//
//  Created by Dexter Leng on 12/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import os

class ObserveFrontmostApplicationService {
    private let disposeBag = DisposeBag()
    
    func observe(_ onApp: @escaping (NSRunningApplication?) -> ()) {
        let disposable = frontmostAppObservable().bind { app in
            onApp(app)
        }
        disposeBag.insert(disposable)
    }
    
    private func frontmostAppObservable() -> Observable<NSRunningApplication?> {
        return Observable.create { observer in
            let center = NSWorkspace.shared.notificationCenter
            center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { notification in
                observer.on(.next(NSWorkspace.shared.frontmostApplication))
            }
            center.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil) { notification in
                observer.on(.next(NSWorkspace.shared.frontmostApplication))
            }
            
            let cancel = Disposables.create {
                center.removeObserver(self)
                os_log("Removed application observer", log: Log.accessibility)
            }
            
            return cancel
        }.distinctUntilChanged()
    }
}
