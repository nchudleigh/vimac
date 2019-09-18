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
    let hintShortcut: MASShortcut
    let scrollShortcut: MASShortcut
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AppNotificationAppPair>
    let windowSubject: BehaviorSubject<UIElement?>
    let overlayEventSubject: PublishSubject<OverlayEvent>
    
    var pressableElementByHint: [String : UIElement]
    var scrollAreaByHint: [String : UIElement]

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
    
    let HINT_TEXT_FIELD_TAG = 1
    let SCROLL_TEXT_FIELD_TAG = 2
    let SCROLL_SELECTOR_TEXT_FIELD_TAG = 3

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
        hintShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .option, .control])
        scrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_C, modifierFlags: [.command, .option, .control])
        pressableElementByHint = [String : UIElement]()
        scrollAreaByHint = [String : UIElement]()
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
                case .hintCommandPressed:
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
                    
                    self.setHintOverlays(window: window, typed: "")
                case .scrollCommandPressed:
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
                    
                    self.setScrollOverlays(window: window, typed: "")
                }
            })
        
        MASShortcutMonitor.shared().register(hintShortcut, withAction: {
            self.overlayEventSubject.onNext(.hintCommandPressed)
        })
        
        MASShortcutMonitor.shared().register(scrollShortcut, withAction: {
            self.overlayEventSubject.onNext(.scrollCommandPressed)
        })
    }
    
    func hideOverlays() {
        os_log("Hiding overlays", log: Log.drawing)
        pressableElementByHint = [String : UIElement]()
        scrollAreaByHint = [String : UIElement]()
        borderWindowController.close()
        self.removeOverlaySubviews()
    }
    
    func removeOverlaySubviews() {
        // delete all current border views
        borderWindowController.window?.contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }
    
    func setScrollOverlays(window: UIElement, typed: String) {
        if let windowPosition: CGPoint = try! window.attribute(.position),
            let windowSize: CGSize = try! window.attribute(.size),
            let borderWindow = borderWindowController.window {
            // show overlay window with borders around scroll areas
            var newOverlayWindowFrame = borderWindow.frame
            newOverlayWindowFrame.origin = Utils.toOrigin(point: windowPosition, size: windowSize)
            newOverlayWindowFrame.size = windowSize
            borderWindowController.window?.setFrame(newOverlayWindowFrame, display: true, animate: false)

            let scrollAreas = traverseUIElementForScrollAreas(element: window, level: 1)
            let borderViews: [BorderView] = scrollAreas
                .map { scrollArea in
                    if let positionFlipped: CGPoint = try! scrollArea.attribute(.position),
                        let size: CGSize = try! scrollArea.attribute(.size) {
                        let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: size)
                        let positionRelativeToWindow = borderWindow.convertPoint(fromScreen: positionRelativeToScreen)
                        return BorderView(frame: NSRect(origin: positionRelativeToWindow, size: size))
                    }
                    return nil
                // filters nil results
                }.compactMap({ $0 })
            
            let hintStrings = AlphabetHints().hintStrings(linkCount: borderViews.count)
            // map buttons to hint views to be added to overlay window
            let range = Int(0)...max(0, Int(borderViews.count-1))
            let hintViews: [HintView] = range
                .map { (index) in
                    let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                    text.initializeHint(hintText: hintStrings[index], typed: typed)
                    return text
                }
            for (index, view) in borderViews.enumerated() {
                view.addSubview(hintViews[index])
                borderWindow.contentView?.addSubview(view)
            }

            let selectorTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            selectorTextField.stringValue = typed
            selectorTextField.isEditable = true
            selectorTextField.delegate = self
            selectorTextField.isHidden = true
            selectorTextField.tag = SCROLL_SELECTOR_TEXT_FIELD_TAG
            borderWindow.contentView?.addSubview(selectorTextField)
            borderWindowController.showWindow(nil)
            borderWindow.makeKeyAndOrderFront(nil)
            selectorTextField.becomeFirstResponder()
        }
    }

    func setHintOverlays(window: UIElement, typed: String) {
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
                        text.initializeHint(hintText: hintStrings[index], typed: typed)
                        let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                        let positionRelativeToWindow = borderWindow.convertPoint(fromScreen: positionRelativeToScreen)
                        text.frame.origin = positionRelativeToWindow
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
            
            let scrollingTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            scrollingTextField.stringValue = typed
            scrollingTextField.isEditable = true
            scrollingTextField.delegate = self
            scrollingTextField.isHidden = true
            scrollingTextField.tag = HINT_TEXT_FIELD_TAG
            borderWindow.contentView?.addSubview(scrollingTextField)
            borderWindowController.showWindow(nil)
            borderWindow.makeKeyAndOrderFront(nil)
            scrollingTextField.becomeFirstResponder()
        }
    }
    
    func traverseUIElementForScrollAreas(element: UIElement, level: Int) -> [UIElement] {
        let roleOptional: Role? = {
            do {
                return try element.role();
            } catch {
                return nil
            }
        }()
        
        if roleOptional == Role.scrollArea {
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
            .map { child in UIElement(child) }
            .map { child in traverseUIElementForScrollAreas(element: child, level: level + 1) }
            .reduce([]) {(result, next) in result + next }
    }
    
    func traverseUIElementForPressables(element: UIElement, level: Int) -> [UIElement] {
        let actionsOptional: [Action]? = {
            do {
                return try element.actions();
            } catch {
                return nil
            }
        }()
        
        let roleOptional: Role? = {
            do {
                return try element.role()
            } catch {
                return nil
            }
        }()
        
        // ignore subcomponents of a scrollbar
        if let role = roleOptional {
            if role == .scrollBar {
                return []
            }
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
        
        let recursiveChildren = children
            .map({child -> [UIElement] in
                return traverseUIElementForPressables(element: UIElement.init(child), level: level + 1)
            })
            .reduce([]) {(result, next) -> [UIElement] in
                return result + next
            }
        
        if let actions = actionsOptional {
            if (actions.contains(.press)) {
                return [element] + recursiveChildren
            }
        }
        
        return recursiveChildren
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        let typed = textField.stringValue
        
        if textField.tag == SCROLL_TEXT_FIELD_TAG {
            var yPixels: CGFloat = 0
            var xPixels: CGFloat = 0
            
            switch (typed.last?.uppercased()) {
            case "J":
                yPixels = -2
                xPixels = 0
            case "K":
                yPixels = 2
                xPixels = 0
            case "H":
                yPixels = 0
                xPixels = 2
            case "L":
                yPixels = 0
                xPixels = -2
            case "D":
                if let overlayWindow = self.borderWindowController.window,
                    let borders = overlayWindow.contentView?.subviews.filter ({ $0 is BorderView }) as! [BorderView]?,
                    let firstBorder = borders.first {
                    if borders.count == 1 && firstBorder.active {
                        yPixels = -1 * (firstBorder.frame.size.height / 2)
                        xPixels = 0
                    }
                }
            case "U":
                if let borders = self.borderWindowController.window?.contentView?.subviews.filter ({ $0 is BorderView }) as! [BorderView]?,
                    let firstBorder = borders.first {
                    if borders.count == 1 {
                        yPixels = firstBorder.frame.size.height / 2
                        xPixels = 0
                    }
                }
            default:
                return
            }
            
            let event = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(yPixels), wheel2: Int32(xPixels), wheel3: 0)!
            //event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64(yPixels))
            //event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(xPixels))
            event.post(tap: .cgSessionEventTap)
        } else if (textField.tag == HINT_TEXT_FIELD_TAG) {
            if let hintViews = borderWindowController.window?.contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? {
                let matchingHintViews = hintViews.filter { $0.stringValue.starts(with: typed.uppercased()) }
                if matchingHintViews.count == 0 && typed.count > 0 {
                    self.hideOverlays()
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
                
                self.removeOverlaySubviews()
                
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
                
                self.setHintOverlays(window: window, typed: typed.uppercased())
            }
        } else if (textField.tag == SCROLL_SELECTOR_TEXT_FIELD_TAG) {
            if let borderWindow = borderWindowController.window,
                let borderViews = borderWindow.contentView?.subviews.filter ({ $0 is BorderView }) as! [BorderView]? {
                let borderViewsWithMatchingHint = borderViews.filter { borderView in
                    let hintView = borderView.subviews.first! as! HintView
                    return hintView.stringValue.starts(with: typed.uppercased())
                }
                if borderViewsWithMatchingHint.count == 0 && typed.count > 0 {
                    self.hideOverlays()
                    return
                }
                
                if borderViewsWithMatchingHint.count == 1 {
                    let borderView = borderViewsWithMatchingHint.first!
                    borderWindowController.window?.contentView?.subviews.forEach { view in
                        if view !== borderView {
                            view.removeFromSuperview()
                        } else {
                            for subview in view.subviews {
                                subview.removeFromSuperview()
                            }
                            borderView.setActive()
                        }
                    }
                    
                    // move mouse to scroll area
                    let mousePositionFlipped = borderWindow.convertPoint(toScreen: borderView.frame.origin)
                    let mousePosition = NSPoint(x: mousePositionFlipped.x + 4, y: NSScreen.screens.first!.frame.size.height - mousePositionFlipped.y - 4)
                    let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: mousePosition, mouseButton: .left)
                    moveEvent?.post(tap: .cgSessionEventTap)
                    
                    let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                    textField.isEditable = true
                    textField.delegate = self
                    textField.isHidden = true
                    textField.tag = SCROLL_TEXT_FIELD_TAG
                    borderWindowController.window?.contentView?.addSubview(textField)
                    textField.becomeFirstResponder()
                    return
                }
                
                self.removeOverlaySubviews()
                
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
                
                self.setHintOverlays(window: window, typed: typed.uppercased())
            }
        }
    }
}
