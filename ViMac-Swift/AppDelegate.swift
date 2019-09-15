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

    let borderWindowController: NSWindowController
    let storyboard: NSStoryboard
    let shortcut: MASShortcut
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AppNotificationAppPair>
    let windowSubject: BehaviorSubject<UIElement?>
    let overlayEventSubject: PublishSubject<OverlayEvent>
    
    var pressableElementByHint: [String : UIElement]

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
        shortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .shift])
        pressableElementByHint = [String : UIElement]()
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
                    
                    self.setOverlays(window: window, typed: "")
                }
            })
        
        MASShortcutMonitor.shared().register(shortcut, withAction: {
            self.overlayEventSubject.onNext(.commandPressed)
        })
    }
    
    func hideOverlays() {
        os_log("Hiding overlays", log: Log.drawing)
        pressableElementByHint = [String : UIElement]()
        borderWindowController.close()
        
        // delete all current border views
        borderWindowController.window?.contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }

    func setOverlays(window: UIElement, typed: String) {
        os_log("Setting overlays for window: %@", log: Log.drawing, String(describing: window))
        if let windowPosition: CGPoint = try! window.attribute(.position),
            let windowSize: CGSize = try! window.attribute(.size),
            let borderWindow = borderWindowController.window {
            
            // resize overlay window so hint views can be drawn onto the screen
            var newOverlayWindowFrame = borderWindow.frame
            newOverlayWindowFrame.origin = Utils.toOrigin(point: windowPosition, size: windowSize)
            newOverlayWindowFrame.size = windowSize
            borderWindowController.window?.setFrame(newOverlayWindowFrame, display: true, animate: false)
            
            let pressableElements = traverseUIElementForPressables(element: window, level: 1)
            
            let hintStrings = AlphabetHints().hintStrings(linkCount: pressableElements.count)
            // map buttons to hint views to be added to overlay window
            let hintViews: [HintView] = pressableElements
                .enumerated()
                .map { (index, button) in
                    if let positionFlipped: CGPoint = try! button.attribute(.position) {
                        let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                        text.initializeHint(hintText: hintStrings[index], typed: typed, positionFlipped: positionFlipped, window: borderWindow)
                        pressableElementByHint[hintStrings[index]] = button
                        return text
                    }
                    return nil
                // filters nil results
                }.compactMap({ $0 })

            hintViews.forEach { view in
                // add view to overlay window
                borderWindowController.window?.contentView?.addSubview(view)
            }
            
            let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            textField.stringValue = typed
            textField.isEditable = true
            textField.delegate = self
            textField.isHidden = true
            borderWindow.contentView?.addSubview(textField)
            borderWindowController.showWindow(nil)
            borderWindow.makeKeyAndOrderFront(nil)
            textField.becomeFirstResponder()
        }
    }
    
    func traverseUIElementForPressables(element: UIElement, level: Int) -> [UIElement] {
        let actionsOptional: [Action]? = {
            do {
                return try element.actions();
            } catch {
                return nil
            }
        }()
        
        guard let actions = actionsOptional else {
            return []
        }
        
        if (actions.contains(.press)) {
            return [element]
        }

        let children: [AXUIElement] = {
            do {
                let childrenOptional = try element.attribute(Attribute.children) as [AXUIElement]?;
                guard let children = childrenOptional else {
                    return []
                }
                return children
            } catch {
                return []
            }
        }()
        return children
            .map({child -> [UIElement] in
                return traverseUIElementForPressables(element: UIElement.init(child), level: level + 1)
            })
            .reduce([]) {(result, next) -> [UIElement] in
                return result + next
            }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        let text = textField.stringValue.uppercased()
        if let hintViews = borderWindowController.window?.contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? {
            let matchingHintViews = hintViews.filter { $0.stringValue.starts(with: text) }
            if matchingHintViews.count == 0 {
                return
            }
            
            if matchingHintViews.count == 1 {
                let hintView = matchingHintViews.first!
                let button = pressableElementByHint[hintView.stringValue]!
                let o: Observable<Void> = Observable.just(Void())
                o
                    .subscribeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { x in
                        do {
                            try button.performAction(.press)
                        } catch {
                        }
                    })
                
                self.hideOverlays()
                return
            }
            
            self.hideOverlays()
            
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
            
            self.setOverlays(window: window, typed: text)
            
        }
    }
}
