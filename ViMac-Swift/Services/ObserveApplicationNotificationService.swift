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

protocol ObserveApplicationNotificationsServiceDelegate: AnyObject {
    func onNotification(pid: pid_t, notification: String, element: AXUIElement)
}

class ObserveApplicationNotificationService {
    let pid: pid_t
    let app: AXUIElement
    let notifications: [String]
    weak var delegate: ObserveApplicationNotificationsServiceDelegate?
    var observer: AXObserver?
    
    init(pid: pid_t, notifications: [String]) {
        self.pid = pid
        self.app = AXUIElementCreateApplication(pid)
        self.notifications = notifications
    }
    
    func start() {
        if self.observer != nil {
            return
        }
        
        guard let observer = createObserver() else { return }
        for notification in notifications {
            addNotification(observer: observer, element: app, notification: notification)
        }
        
        CFRunLoopAddSource(
            RunLoop.current.getCFRunLoop(),
            AXObserverGetRunLoopSource(observer),
            CFRunLoopMode.defaultMode)
        
        self.observer = observer
    }
    
    func createObserver() -> AXObserver? {
        var observer: AXObserver?
        let error = AXObserverCreate(pid, { _, element, notification, userData in
            guard let userData = userData else { return }
            let _self = Unmanaged<ObserveApplicationNotificationService>.fromOpaque(userData).takeUnretainedValue()
            _self.onNotification(element, notification as String)
        }, &observer)
        
        if error != .success {
            os_log("AXObserverCreate failed with error %@", error.rawValue)
            return nil
        }
        
        return observer!
    }
    
    func addNotification(observer: AXObserver, element: AXUIElement, notification: String) {
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let error = AXObserverAddNotification(observer, element, notification as CFString, selfPtr)
    if error != .success {
            os_log("AXObserverAddNotification %@ failed with error code %@", notification, String(describing: error.rawValue) )
            return
        }
        return
    }
    
    func stop() {
        guard let observer = self.observer else { return }
        
        CFRunLoopRemoveSource(
            RunLoop.current.getCFRunLoop(),
            AXObserverGetRunLoopSource(observer),
            CFRunLoopMode.defaultMode)
    }
    
    func onNotification(_ element: AXUIElement,
                        _ notification: String) {
        os_log("New app notification: %@", log: Log.accessibility, notification)
        
        self.delegate?.onNotification(pid: pid, notification: notification, element: element)
    }
}
