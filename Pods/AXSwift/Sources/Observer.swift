import Cocoa
import Foundation
import Darwin

/// Observers watch for events on an application's UI elements.
///
/// Events are received as part of the application's default run loop.
///
/// - seeAlso: `UIElement` for a list of exceptions that can be thrown.
public final class Observer {
    public typealias Callback = (_ observer: Observer,
                                 _ element: UIElement,
                                 _ notification: AXNotification) -> Void
    public typealias CallbackWithInfo = (_ observer: Observer,
                                         _ element: UIElement,
                                         _ notification: AXNotification,
                                         _ info: [String: AnyObject]?) -> Void

    let pid: pid_t
    let axObserver: AXObserver!
    let callback: Callback?
    let callbackWithInfo: CallbackWithInfo?

    public fileprivate(set) lazy var application: Application =
        Application(forKnownProcessID: self.pid)!

    /// Creates and starts an observer on the given `processID`.
    public init(processID: pid_t, callback: @escaping Callback) throws {
        var axObserver: AXObserver?
        let error = AXObserverCreate(processID, internalCallback, &axObserver)

        pid = processID
        self.axObserver = axObserver
        self.callback = callback
        callbackWithInfo = nil

        guard error == .success else {
            throw error
        }
        assert(axObserver != nil)

        start()
    }

    /// Creates and starts an observer on the given `processID`.
    ///
    /// Use this initializer if you want the extra user info provided with notifications.
    /// - seeAlso: [UserInfo Keys for Posting Accessibility Notifications](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/doc/constant_group/UserInfo_Keys_for_Posting_Accessibility_Notifications)
    public init(processID: pid_t, callback: @escaping CallbackWithInfo) throws {
        var axObserver: AXObserver?
        let error = AXObserverCreateWithInfoCallback(processID, internalInfoCallback, &axObserver)

        pid = processID
        self.axObserver = axObserver
        self.callback = nil
        callbackWithInfo = callback

        guard error == .success else {
            throw error
        }
        assert(axObserver != nil)

        start()
    }

    deinit {
        stop()
    }

    /// Starts watching for events. You don't need to call this method unless you use `stop()`.
    ///
    /// If the observer has already been started, this method does nothing.
    public func start() {
        CFRunLoopAddSource(
            RunLoop.current.getCFRunLoop(),
            AXObserverGetRunLoopSource(axObserver),
            CFRunLoopMode.defaultMode)
    }

    /// Stops sending events to your callback until the next call to `start`.
    ///
    /// If the observer has already been started, this method does nothing.
    ///
    /// - important: Events will still be queued in the target process until the Observer is started
    ///              again or destroyed. If you don't want them, create a new Observer.
    public func stop() {
        CFRunLoopRemoveSource(
            RunLoop.current.getCFRunLoop(),
            AXObserverGetRunLoopSource(axObserver),
            CFRunLoopMode.defaultMode)
    }

    /// Adds a notification for the observer to watch.
    ///
    /// - parameter notification: The name of the notification to watch for.
    /// - parameter forElement: The element to watch for the notification on. Must belong to the
    ///                         application this observer was created on.
    /// - seeAlso: [Notificatons](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/c/data/NSAccessibilityAnnouncementRequestedNotification)
    /// - note: The underlying API returns an error if the notification is already added, but that
    ///         error is not passed on for consistency with `start()` and `stop()`.
    /// - throws: `Error.NotificationUnsupported`: The element does not support notifications (note
    ///           that the system-wide element does not support notifications).
    public func addNotification(_ notification: AXNotification,
                                forElement element: UIElement) throws {
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let error = AXObserverAddNotification(
            axObserver, element.element, notification.rawValue as CFString, selfPtr
        )
        guard error == .success || error == .notificationAlreadyRegistered else {
            throw error
        }
    }

    /// Removes a notification from the observer.
    ///
    /// - parameter notification: The name of the notification to stop watching.
    /// - parameter forElement: The element to stop watching the notification on.
    /// - note: The underlying API returns an error if the notification is not present, but that
    ///         error is not passed on for consistency with `start()` and `stop()`.
    /// - throws: `Error.NotificationUnsupported`: The element does not support notifications (note
    ///           that the system-wide element does not support notifications).
    public func removeNotification(_ notification: AXNotification,
                                   forElement element: UIElement) throws {
        let error = AXObserverRemoveNotification(
            axObserver, element.element, notification.rawValue as CFString
        )
        guard error == .success || error == .notificationNotRegistered else {
            throw error
        }
    }
}

private func internalCallback(_ axObserver: AXObserver,
                              axElement: AXUIElement,
                              notification: CFString,
                              userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else { fatalError("userData should be an AXSwift.Observer") }

    let observer = Unmanaged<Observer>.fromOpaque(userData).takeUnretainedValue()
    let element = UIElement(axElement)
    guard let notif = AXNotification(rawValue: notification as String) else {
        NSLog("Unknown AX notification %s received", notification as String)
        return
    }
    observer.callback!(observer, element, notif)
}

private func internalInfoCallback(_ axObserver: AXObserver,
                                  axElement: AXUIElement,
                                  notification: CFString,
                                  cfInfo: CFDictionary,
                                  userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else { fatalError("userData should be an AXSwift.Observer") }

    let observer = Unmanaged<Observer>.fromOpaque(userData).takeUnretainedValue()
    let element = UIElement(axElement)
    let info = cfInfo as NSDictionary? as! [String: AnyObject]?
    guard let notif = AXNotification(rawValue: notification as String) else {
        NSLog("Unknown AX notification %s received", notification as String)
        return
    }
    observer.callbackWithInfo!(observer, element, notif, info)
}
