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
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // This struct allows us to propagate the original source value (application) when doing a flatMap/flatMapLatest to get the notification.
    struct AppNotificationAppPair {
        let app: Application?
        let notification: AXNotification?
    }
    
    //var controllers: [NSWindowController]
    var borderWindowController: NSWindowController?
    var storyboard: NSStoryboard
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AppNotificationAppPair>

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]

    static func createApplicationObservable() -> Observable<Application?> {
        return Observable.create { observer in
            let center = NSWorkspace.shared.notificationCenter
            center.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil) { notification in
                if let nsApplication = NSWorkspace.shared.frontmostApplication,
                    let application = Application.init(nsApplication) {
                    os_log("New frontmost application")
                    observer.on(.next(application))
                } else {
                    os_log("No frontmost applications")
                    observer.on(.next(nil))
                }
            }
            let cancel = Disposables.create {
                center.removeObserver(self)
                os_log("Application observable disposed")
            }
            
            return cancel
        }
    }
    
    static func createApplicationNotificationObservable(applicationObservable: Observable<Application?>) -> Observable<AppNotificationAppPair> {
        return applicationObservable
            .flatMapLatest { appOptional -> Observable<AppNotificationAppPair> in
                if let app = appOptional {
                    return Observable.create { observer in
                        // currently, overlays are drawn when the .focusedWindowChanged event is emitted.
                        // to allow the overlays to shown for the initial window, we check if there is a focused window and emit the event if there is.
                        // this is a hack and a better solution is needed.
                        // we can consider extending AXNotification to include a initialWindow event
                        let windowOptional: UIElement? = {
                            do {
                                return try app.attribute(Attribute.focusedWindow)
                            } catch {
                                return nil
                            }
                        }()
                        
                        if let window = windowOptional {
                            let pair = AppNotificationAppPair(app: app, notification: .focusedWindowChanged)
                            observer.on(.next(pair))
                        }
                        
                        let notificationObserver = app.createObserver { (_observer: Observer, _element: UIElement, event: AXNotification) in
                            os_log("New App Notification")
                            let pair = AppNotificationAppPair(app: app, notification: event)
                            observer.on(.next(pair))
                        }
                        
                        let events = [AXNotification.focusedWindowChanged] + windowEvents
                        for event in events {
                            try! notificationObserver?.addNotification(event, forElement: app)
                        }
                        
                        let cancel = Disposables.create {
                            for event in events {
                                try! notificationObserver?.removeNotification(event, forElement: app)
                            }
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
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }

        applicationNotificationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { pair in
                if let notification = pair.notification,
                    let app = pair.app {
                    if notification == .focusedWindowChanged {
                        os_log("Focused window changed")
                        let windowOptional: UIElement? = {
                            do {
                                return try app.attribute(Attribute.focusedWindow)
                            } catch {
                                return nil
                            }
                        }()
                        if let window = windowOptional {
                            self.setOverlays(window: window)
                        } else {
                            self.hideOverlays()
                        }
                    } else if (AppDelegate.windowEvents.contains(notification)) {
                        self.hideOverlays()
                    }
                }
            })
    }
    
    func hideOverlays() {
        os_log("Hiding overlays")
        borderWindowController?.close()
        
        // delete all current border views
        borderWindowController?.window?.contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }

    func setOverlays(window: UIElement) {
        hideOverlays()
        
        if let windowPosition: CGPoint = try! window.attribute(.position),
            let windowSize: CGSize = try! window.attribute(.size),
            let borderWindow = borderWindowController?.window {
            
            // resize overlay window so border views can be drawn onto the screen
            var newOverlayWindowFrame = borderWindow.frame
            newOverlayWindowFrame.origin = toOrigin(point: windowPosition, size: windowSize)
            newOverlayWindowFrame.size = windowSize
            borderWindowController?.window?.setFrame(newOverlayWindowFrame, display: true, animate: false)
            
            // add border views to overlay window
            let buttons = traverseUIElementForButtons(element: window, level: 1)
            for button in buttons {
                if let position: CGPoint = try! button.attribute(.position),
                    let size: CGSize = try! button.attribute(.size) {
                    let screenRect = NSRect(origin: toOrigin(point: position, size: size), size: size)
                    // convert screen coordinate to window coordinate
                    let windowRect = borderWindow.convertFromScreen(screenRect)
                    let borderView = BorderView(frame: windowRect)
                    borderWindowController?.window?.contentView?.addSubview(borderView)
                }
            }
            
            borderWindowController?.showWindow(nil)
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
