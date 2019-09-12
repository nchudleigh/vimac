//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import MASShortcut
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // This struct allows us to propagate the original source value (application) when doing a flatMap/flatMapLatest to get the notification.
    struct AppNotificationAppPair {
        let app: Application?
        let notification: AXNotification?
    }

    var borderWindowController: NSWindowController
    var storyboard: NSStoryboard
    let shortcut: MASShortcut
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AppNotificationAppPair>
    let windowSubject: BehaviorSubject<UIElement?>
    let overlayEventSubject: PublishSubject<OverlayEvent>

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]

    static func createApplicationObservable() -> Observable<Application?> {
        return Observable.create { observer in
            let center = NSWorkspace.shared.notificationCenter
            center.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil) { notification in
                if let nsApplication = NSWorkspace.shared.frontmostApplication,
                    let application = Application.init(nsApplication) {
                    os_log("Current frontmost application: %@", log: Log.accessibility, String(describing: application))
                    observer.on(.next(application))
                } else {
                    os_log("Current frontmost application: nil", log: Log.accessibility)
                    observer.on(.next(nil))
                }
            }
            let cancel = Disposables.create {
                center.removeObserver(self)
                os_log("Removed application observer", log: Log.accessibility)
            }
            
            return cancel
        }
    }
    
    static func createApplicationNotificationObservable(applicationObservable: Observable<Application?>) -> Observable<AppNotificationAppPair> {
        return applicationObservable
            .flatMapLatest { appOptional -> Observable<AppNotificationAppPair> in
                if let app = appOptional {
                    return Observable.create { observer in
                        let notificationObserver = app.createObserver { (_observer: Observer, _element: UIElement, event: AXNotification) in
                            os_log("New app notification: %@", log: Log.accessibility, String(describing: event))
                            let pair = AppNotificationAppPair(app: app, notification: event)
                            observer.on(.next(pair))
                        }
                        
                        let events = [AXNotification.focusedWindowChanged] + windowEvents
                        for event in events {
                            do {
                                try notificationObserver?.addNotification(event, forElement: app)
                            } catch {
                                os_log("Error adding notification observer for event: %@ and application %@. Error: %@", log: Log.accessibility, type: .error, String(describing: event), String(describing: app), String(describing: error))
                            }
                        }
                        
                        let cancel = Disposables.create {
                            
                            for event in events {
                                do {
                                    try notificationObserver?.removeNotification(event, forElement: app)
                                } catch {
                                    os_log("Error removing notification observer for event: %@ and application %@. Error: %@", log: Log.accessibility, type: .error, String(describing: event), String(describing: app), String(describing: error))
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
    
    override init() {
        storyboard =
            NSStoryboard.init(name: "Main", bundle: nil)
        borderWindowController = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
        applicationObservable = AppDelegate.createApplicationObservable().share()
        applicationNotificationObservable = AppDelegate.createApplicationNotificationObservable(applicationObservable: applicationObservable)
        windowSubject = BehaviorSubject(value: nil)
        overlayEventSubject = PublishSubject()
        shortcut =  MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .shift])
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        applicationObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { appOptional in
                if let app = appOptional {
                    let windowOptional: UIElement? = {
                        do {
                            return try app.attribute(Attribute.focusedWindow)
                        } catch {
                            return nil
                        }
                    }()
                    self.windowSubject.onNext(windowOptional)
                }
            })

        applicationNotificationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { pair in
                if let notification = pair.notification,
                    let app = pair.app {
                    if notification == .focusedWindowChanged {
                        let windowOptional: UIElement? = {
                            do {
                                return try app.attribute(Attribute.focusedWindow)
                            } catch {
                                return nil
                            }
                        }()
                        self.windowSubject.onNext(windowOptional)
                        return
                    }
                    
                    if (AppDelegate.windowEvents.contains(notification)) {
                        self.overlayEventSubject.onNext(.activeWindowUpdated)
                        return
                    }
                }
            })
        
        windowSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                os_log("Current window: %@", log: Log.accessibility, String(describing: windowOptional))
                guard let window = windowOptional else {
                    self.overlayEventSubject.onNext(.noActiveWindow)
                    return
                }
                self.overlayEventSubject.onNext(.newActiveWindow)
            })
        
        overlayEventSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { event in
                switch event {
                case .newActiveWindow:
                    self.hideOverlays()
                case .noActiveWindow:
                    self.hideOverlays()
                case .activeWindowUpdated:
                    self.hideOverlays()
                case .commandPressed:
                    if self.borderWindowController.window!.contentView!.subviews.count > 0 {
                        self.hideOverlays()
                        return
                    }
                    
                    let windowOptional: UIElement? = {
                        do {
                            return try self.windowSubject.value()
                        } catch {
                            return nil
                        }
                    }()
                    
                    guard let window = windowOptional else {
                        return
                    }
                    
                    self.setOverlays(window: window)
                }
            })
        
        MASShortcutMonitor.shared().register(shortcut, withAction: {
            self.overlayEventSubject.onNext(.commandPressed)
        })
    }
    
    func hideOverlays() {
        os_log("Hiding overlays", log: Log.drawing)
        borderWindowController.close()
        
        // delete all current border views
        borderWindowController.window?.contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }

    func setOverlays(window: UIElement) {
        os_log("Setting overlays for window: %@", log: Log.drawing, String(describing: window))
        if let windowPosition: CGPoint = try! window.attribute(.position),
            let windowSize: CGSize = try! window.attribute(.size),
            let borderWindow = borderWindowController.window {
            
            // resize overlay window so border views can be drawn onto the screen
            var newOverlayWindowFrame = borderWindow.frame
            newOverlayWindowFrame.origin = toOrigin(point: windowPosition, size: windowSize)
            newOverlayWindowFrame.size = windowSize
            borderWindowController.window?.setFrame(newOverlayWindowFrame, display: true, animate: false)
            
            // add border views to overlay window
            let buttons = traverseUIElementForButtons(element: window, level: 1)
            for button in buttons {
                if let position: CGPoint = try! button.attribute(.position),
                    let size: CGSize = try! button.attribute(.size) {
                    let screenRect = NSRect(origin: toOrigin(point: position, size: size), size: size)
                    // convert screen coordinate to window coordinate
                    let windowRect = borderWindow.convertFromScreen(screenRect)
                    let borderView = BorderView(frame: windowRect)
                    borderWindowController.window?.contentView?.addSubview(borderView)
                }
            }
            
            borderWindowController.showWindow(nil)
        }
    }
    
    func traverseUIElementForButtons(element: UIElement, level: Int) -> [UIElement] {
        let role = try! element.role();
        if (role == Role.button) {
            return [element]
        }
        
        let children = try! element.attribute(Attribute.children) as [AXUIElement]?;
        if let unwrappedChildren = children {
            return unwrappedChildren
                .map({child -> [UIElement] in
                    return traverseUIElementForButtons(element: UIElement.init(child), level: level + 1)
                })
                .reduce([]) {(result, next) -> [UIElement] in
                    return result + next
                }
        }
        return []
    }
    
    func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        let screenHeight = NSScreen.screens.first?.frame.size.height
        return CGPoint(x: point.x, y: screenHeight! - size.height - point.y)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
