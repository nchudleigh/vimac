//
//  AccessibilityObservables.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 18/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift
import AXSwift
import os

class AccessibilityObservables: NSObject {
    // This struct allows us to propagate the original source value (application) when doing a flatMap/flatMapLatest to get the notification.
    struct AppNotificationAppPair {
        let app: Application?
        let notification: AXNotification?
    }
    
    static func createApplicationObservable() -> Observable<Application?> {
        let nsApplicationObservable: Observable<NSRunningApplication?> = Observable.create { observer in
            func onApplicationChange() -> Void {
                observer.on(.next(NSWorkspace.shared.frontmostApplication))
            }
            
            let center = NSWorkspace.shared.notificationCenter
            center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { notification in
                onApplicationChange()
            }
            center.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil) { notification in
                onApplicationChange()
            }
            
            let cancel = Disposables.create {
                center.removeObserver(self)
                os_log("Removed application observer", log: Log.accessibility)
            }
            
            return cancel
        }.distinctUntilChanged()
        return nsApplicationObservable
            .map { nsAppOptional in
                guard let nsApp = nsAppOptional else {
                    return nil
                }
                return Application.init(nsApp)
        }
    }
    
    static func createApplicationNotificationObservable(applicationObservable: Observable<Application?>, notifications: [AXNotification]) -> Observable<AppNotificationAppPair> {
        return applicationObservable
            .flatMapLatest { appOptional -> Observable<AppNotificationAppPair> in
                if let app = appOptional {
                    return Observable.create { observer in
                        let notificationObserver = app.createObserver { (_observer: Observer, _element: UIElement, event: AXNotification) in
                            os_log("New app notification: %@", log: Log.accessibility, String(describing: event))
                            let pair = AppNotificationAppPair(app: app, notification: event)
                            observer.on(.next(pair))
                        }
                        
                        for notification in notifications {
                            do {
                                try notificationObserver?.addNotification(notification, forElement: app)
                            } catch {
                                os_log("Error adding notification observer for event: %@ and application %@. Error: %@", log: Log.accessibility, type: .error, String(describing: notification), String(describing: app), String(describing: error))
                            }
                        }
                        
                        let cancel = Disposables.create {
                            
                            for notification in notifications {
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
                } else {
                    return Observable.just(AppNotificationAppPair(app: nil, notification: nil))
                }
        }
    }
}
