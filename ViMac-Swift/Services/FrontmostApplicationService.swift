//
//  FrontmostApplicationService.swift
//  Vimac
//
//  Created by Dexter Leng on 12/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import AXSwift
import os

class FrontmostApplicationService {
    struct ApplicationNotification {
        let app: NSRunningApplication
        let notification: String
    }
    
    private let disposeBag = DisposeBag()
    private lazy var frontmostApplicationObservable: Observable<NSRunningApplication?> =
        createFrontmostApplicationObservable()
            .do(onNext: { app in
                os_log("Current frontmost application: %@", log: Log.accessibility, String(describing: app))
            })
            .share()
    private lazy var applicationNotificationObservable: Observable<ApplicationNotification> = createApplicationNotificationObservable().share()
    private lazy var focusedWindowObservable: Observable<Element?> =
        Observable
            .merge([
                createInitialFocusedWindowObservable(),
                createFocusedWindowObservable()
            ])
            .do(onNext: { window in
                os_log("Current window: %@", log: Log.accessibility, String(describing: window))
            })
            .share()

    private lazy var focusedWindowDisturbedObservable: Observable<ApplicationNotification> = createFocusedWindowDisturbedObservable().share()
    
    func observeFrontmostApp(_ onApp: @escaping (NSRunningApplication?) -> ()) {
        let disposable = frontmostApplicationObservable.bind { app in
            onApp(app)
        }
        disposeBag.insert(disposable)
    }
    
    func observeFocusedWindow(_ onFocus: @escaping (Element?) -> ()) {
        let disposable = focusedWindowObservable.bind { window in
            onFocus(window)
        }
        disposeBag.insert(disposable)
    }
    
    func observeFocusedWindowDisturbed(_ onDisturbed: @escaping (ApplicationNotification) -> ()) {
        let disposable = focusedWindowDisturbedObservable.bind { notification in
            onDisturbed(notification)
        }
        disposeBag.insert(disposable)
    }
    
    private func createFrontmostApplicationObservable() -> Observable<NSRunningApplication?> {
        Observable.create { observer in
            let service = ObserveFrontmostApplicationService.init()
            service.observe({ app in
                observer.onNext(app)
            })
            return Disposables.create()
        }
    }
    
    private func createApplicationNotificationObservable() -> Observable<ApplicationNotification> {
        frontmostApplicationObservable
            .compactMap({ $0 })
            .flatMapLatest({ app -> Observable<ApplicationNotification> in
                let serviceOptional = ObserveApplicationNotificationService.fromNSRunningApplication(app)
                guard let service = serviceOptional else { return Observable.empty() }
                
                let windowNotifications: [AXNotification] = [
                    .windowMiniaturized,
                    .windowMoved,
                    .windowResized,
                    .focusedWindowChanged
                ]
                let windowNotificationsStr = windowNotifications.map({ $0.rawValue })
                
                return Observable.create { observer in
                    service.observe(notifications: windowNotificationsStr, { notification in
                        observer.onNext(ApplicationNotification(
                            app: app,
                            notification: notification
                        ))
                    })
                    return Disposables.create { service /* keeping a reference here to prevent the service from being GC'd */ }
                }
            })
    }

    private func createInitialFocusedWindowObservable() -> Observable<Element?> {
        frontmostApplicationObservable.map { appOptional in
            guard let app = appOptional else { return nil }
            let windowOptional: UIElement? = try? Application(app)?.attribute(Attribute.focusedWindow)
            guard let window = windowOptional else { return nil }
            return Element.initialize(rawElement: window.element)
        }
    }
    
    private func createFocusedWindowObservable() -> Observable<Element?> {
        applicationNotificationObservable
            .filter { $0.notification == AXNotification.focusedWindowChanged.rawValue }
            .map { notification in
                let windowOptional: UIElement? = try? Application(notification.app)?.attribute(Attribute.focusedWindow)
                guard let window = windowOptional else { return nil }
                return Element.initialize(rawElement: window.element)
            }
    }
    
    private func createFocusedWindowDisturbedObservable() -> Observable<ApplicationNotification> {
        applicationNotificationObservable
            .filter { notification in
                let disturbedNotifications: [AXNotification] = [
                    .windowMiniaturized,
                    .windowMoved,
                    .windowResized,
                ]
                let disturbedNotificationsStr = disturbedNotifications.map({ $0.rawValue })
                return disturbedNotificationsStr.contains(notification.notification)
            }
    }
}
