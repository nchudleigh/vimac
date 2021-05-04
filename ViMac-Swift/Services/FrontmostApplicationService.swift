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
        let pid: pid_t
        let notification: String
        let element: AXUIElement
    }
    
    private let disposeBag = DisposeBag()
    private lazy var frontmostApplicationObservable: Observable<NSRunningApplication?> =
        createFrontmostApplicationObservable()
            .do(onNext: { app in
                os_log("Current frontmost application: %@", log: Log.accessibility, String(describing: app))
            })
            .share()
    
    var observeAppNotificationService: ObserveApplicationNotificationService?
    private let _applicationNotification = PublishSubject<ApplicationNotification>()
    private lazy var applicationNotificationObservable: Observable<ApplicationNotification> = _applicationNotification.asObservable()
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
    
    init() {
        frontmostApplicationObservable
            .compactMap({ $0 })
            .bind(onNext: { [weak self] app in
                guard let self = self else { return }
                
                if let service = self.observeAppNotificationService {
                    service.stop()
                }
                let service = ObserveApplicationNotificationService(pid: app.processIdentifier, notifications: [
                    kAXWindowMiniaturizedNotification,
                    kAXWindowMovedNotification,
                    kAXFocusedWindowChangedNotification,
                    kAXMenuOpenedNotification,
                    kAXMenuClosedNotification
                ])
                service.delegate = self
                service.start()
                self.observeAppNotificationService = service
            })
            .disposed(by: self.disposeBag)
    }
    
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
    
    func observeMenuOpened(_ onEvent: @escaping (_ element: AXUIElement) -> ()) {
        applicationNotificationObservable
            .filter { $0.notification == kAXMenuOpenedNotification }
            .bind { notification in
                onEvent(notification.element)
            }
            .disposed(by: self.disposeBag)
    }
    
    func observeMenuClosed(_ onEvent: @escaping (_ element: AXUIElement) -> ()) {
        applicationNotificationObservable
            .filter { $0.notification == kAXMenuClosedNotification }
            .bind { notification in
                onEvent(notification.element)
            }
            .disposed(by: self.disposeBag)
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
                let windowOptional: UIElement? = try? Application(forProcessID: notification.pid)?.attribute(Attribute.focusedWindow)
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
                ]
                let disturbedNotificationsStr = disturbedNotifications.map({ $0.rawValue })
                return disturbedNotificationsStr.contains(notification.notification)
            }
    }
}

extension FrontmostApplicationService: ObserveApplicationNotificationsServiceDelegate {
    func onNotification(pid: pid_t, notification: String, element: AXUIElement) {
        _applicationNotification.onNext(.init(
            pid: pid,
            notification: notification,
            element: element
        ))
    }
}
