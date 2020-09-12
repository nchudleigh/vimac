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
    private lazy var frontmostApplicationObservable: Observable<NSRunningApplication?> = createFrontmostApplicationObservable().share()
    private lazy var applicationNotificationObservable: Observable<ApplicationNotification> = createApplicationNotificationObservable().share()
    
    func observeFrontmostApp(_ onApp: @escaping (NSRunningApplication?) -> ()) {
        let disposable = frontmostApplicationObservable.bind { app in
            onApp(app)
        }
        disposeBag.insert(disposable)
    }
    
    func observeAppNotification(_ onNotification: @escaping (ApplicationNotification) -> ()) {
        let disposable = applicationNotificationObservable.bind { notification in
            onNotification(notification)
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
                    return Disposables.create { service } 
                }
            })
    }
}
