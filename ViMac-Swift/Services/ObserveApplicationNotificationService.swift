//
//  ObserveApplicationNotificationService.swift
//  Vimac
//
//  Created by Dexter Leng on 12/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import AXSwift
import os

class ObserveApplicationNotificationService {
    let app: AXUIElement
    private let disposeBag = DisposeBag()
    
    init(app: AXUIElement) {
        self.app = app
    }
    
    static func fromNSRunningApplication(_ nsApp: NSRunningApplication) -> ObserveApplicationNotificationService? {
        let processId = nsApp.processIdentifier
        if processId < 0 { return nil }
        let rawElement = AXUIElementCreateApplication(processId)
        return ObserveApplicationNotificationService.init(app: rawElement)
    }
    
    func observe(notifications: [String], _ onNotification: @escaping (String) -> ()) {
        let disposable = notificationObservable(notifications: notifications).bind { notification in
            onNotification(notification)
        }
        disposeBag.insert(disposable)
    }
    
    func notificationObservable(notifications: [String]) -> Observable<String> {
        let app = Application(self.app)
        let axSwiftNotifications = notifications
            .map { AXNotification(rawValue: $0) }
            .compactMap { $0 }
        
        return Observable.create { observer in
            let notificationObserver = app.createObserver { (_observer: Observer, _element: UIElement, event: AXNotification) in
                os_log("New app notification: %@", log: Log.accessibility, String(describing: event))
                observer.onNext(event.rawValue)
            }
            
            for notification in axSwiftNotifications {
                do {
                    try notificationObserver?.addNotification(notification, forElement: app)
                } catch {
                    os_log("Error adding notification observer for event: %@ and application %@. Error: %@", log: Log.accessibility, type: .error, String(describing: notification), String(describing: app), String(describing: error))
                }
            }
            
            let cancel = Disposables.create {
                
                for notification in axSwiftNotifications {
                    do {
                        try notificationObserver?.removeNotification(notification, forElement: app)
                    } catch {
                        os_log("Error removing notification observer for event: %@ and application %@. Error: %@", log: Log.accessibility, type: .error, String(describing: notification), String(describing: app), String(describing: error))
                    }
                }
                os_log("Removed notification observers for %@.", log: Log.accessibility, String(describing: app))
            }
            return cancel
        }
    }
}
