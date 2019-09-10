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

    var controllers: [NSWindowController]
    var storyboard: NSStoryboard
    
    let applicationObservable: Observable<Application?>
    let windowObservable: Observable<UIElement?>
    let cancelTrackingObservable: Observable<Void>

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
    
    static func createWindowObservable(applicationObservable: Observable<Application?>) -> Observable<UIElement?> {
        return applicationObservable
            .flatMapLatest { appOptional -> Observable<UIElement?> in
                if let app = appOptional {
                    return Observable.create { observer in
                        let windowOptional: UIElement? = {
                            do {
                                return try app.attribute(Attribute.focusedWindow)
                            } catch {
                                return nil
                            }
                        }()
                        if let window = windowOptional {
                            observer.on(.next(window))
                        }

                        let newWindowObserver = app.createObserver { (_observer: Observer, _element: UIElement, _event: AXNotification) in
                            let window: UIElement? = {
                                do {
                                    return try app.attribute(Attribute.focusedWindow)
                                } catch {
                                    return nil
                                }
                            }()
                            os_log("Focused window changed")
                            observer.on(.next(window))
                        }
                        
                        try! newWindowObserver?.addNotification(.focusedWindowChanged, forElement: app)
                        
                        let cancel = Disposables.create {
                            os_log("Window observable disposed")
                            try! newWindowObserver?.removeNotification(.focusedWindowChanged, forElement: app)
                        }
                        return cancel
                    }
                } else {
                    return Observable.just(nil)
                }
        }
    }

    static func createCancelTrackingObservable(windowObservable: Observable<UIElement?>) -> Observable<Void> {
        return windowObservable
            .flatMapLatest { windowOptional -> Observable<Void> in
                if let window = windowOptional {
                    return Observable.create { observer in
                        let windowUpdatedObserver = try! Observer.init(processID: window.pid(), callback: { (_observer: Observer, _element: UIElement, _event: AXNotification) in
                            observer.on(.next(Void()))
                        })

                        // events that do not cause active window to change
                        let events: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
                        
                        for event in events {
                            try! windowUpdatedObserver.addNotification(event, forElement: window)
                        }
                        
                        let cancel = Disposables.create {
                            os_log("Should Cancel observable disposed")
                            for event in events {
                                try! windowUpdatedObserver.removeNotification(event, forElement: window)
                            }
                        }
                        return cancel
                    }
                } else {
                    return Observable.empty()
                }
            }
    }
    
    override init() {
        controllers = [NSWindowController]()
        storyboard =
            NSStoryboard.init(name: "Main", bundle: nil)
        applicationObservable = AppDelegate.createApplicationObservable()
        windowObservable = AppDelegate.createWindowObservable(applicationObservable: applicationObservable)
        cancelTrackingObservable = AppDelegate.createCancelTrackingObservable(windowObservable: windowObservable)
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        windowObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                if let window = windowOptional {
                    self.setOverlays(window: window)
                }
            })
        
        cancelTrackingObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                self.hideOverlays()
            })
    }
    
    func hideOverlays() {
        controllers.forEach({(controller) -> Void in
            controller.close()
        })
        controllers.removeAll()
    }

    func setOverlays(window: UIElement) {
        hideOverlays()
        
        let buttons = traverseUIElementForButtons(element: window, level: 1)
        for button in buttons {
            if let position: CGPoint = try! button.attribute(.position),
                let size: CGSize = try! button.attribute(.size) {
                let controller = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
                let frame = controller.window?.frame
                if var uFrame = frame {
                    uFrame.origin = toOrigin(point: position, size: size)
                    uFrame.size = size
                    controller.window?.setFrame(uFrame, display: true, animate: false)
                    controller.window?.orderFront(nil)
                }
                
                controller.showWindow(nil)
                controllers.append(controller)
            }
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

