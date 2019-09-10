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
    var optionalObserver: Observer?
    let events: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized, .focusedWindowChanged]
    var optionalApplication: Application?
    
    let application: Observable<Application?>

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
    
    override init() {
        controllers = [NSWindowController]()
        storyboard =
            NSStoryboard.init(name: "Main", bundle: nil)
        application = AppDelegate.createApplicationObservable()
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }

        updateOverlays()
        listenForDeactivatedApplication()
    }
    
    func listenForDeactivatedApplication() {
//        let center =  NSWorkspace.shared.notificationCenter
//        center.addObserver(self, selector: #selector(AppDelegate.updateOverlays), name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
    }
    
    @objc func updateOverlays() {
        controllers.forEach({(controller) -> Void in
            controller.close()
        })
        controllers.removeAll()
        
        if let application = optionalApplication,
            let observer = optionalObserver {
            detachObserver(application: application, observer: observer)
            optionalApplication = nil
            optionalObserver = nil
        }
        
        if let nsApplication = NSWorkspace.shared.frontmostApplication,
            let application = Application.init(nsApplication) {
            optionalApplication = application
            optionalObserver = attachObserverToApplication(application: application)
            let optionalFocusedWindow: UIElement? = try! application.attribute(Attribute.focusedWindow)
            if let focusedWindow = optionalFocusedWindow {
                let buttons = traverseUIElementForButtons(element: focusedWindow, level: 1)
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
        }
    }
    
    func attachObserverToApplication(application: Application) -> Observer {
        let optionalObserver = application.createObserver { (observer: Observer, element: UIElement, event: AXNotification) in
            self.updateOverlays()
        }
        
        for event in events {
            try! optionalObserver?.addNotification(event, forElement: application)
        }
        
        return optionalObserver!
    }
    
    func detachObserver(application: Application, observer: Observer) {
        for event in events {
            try! observer.removeNotification(event, forElement: application)
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

