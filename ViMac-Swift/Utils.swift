//  ViMac-Swift
//
//  Created by Dexter Leng on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import MASShortcut
import RxSwift

class Utils: NSObject {
    static let defaultHintShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.control])
    static let defaultScrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_S, modifierFlags: [.control])
    static let hintModeShortcutKey = "HintModeShortcut"
    static let scrollModeShortcutKey = "ScrollModeShortcut"
    static let forceKeyboardLayoutKey = "ForceKeyboardLayout"
    static let shouldLaunchOnStartupKey = "ShouldLaunchOnStartupKey"
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Utils.shouldLaunchOnStartupKey: false,
        ])
    }
    
    // This function returns the position of the point after the y-axis is flipped.
    // We need this because accessing the position of a AXUIElement gives us the position from top-left,
    // but the coordinate system in macOS starts from bottom-left.
    // https://developer.apple.com/documentation/applicationservices/kaxpositionattribute?language=objc
    static func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        let screenHeight = NSScreen.screens.first!.frame.height
        return CGPoint(x: point.x, y: screenHeight - size.height - point.y)
    }
    
    static func moveMouse(position: CGPoint) {
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    static func leftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        // for some reason you need to do this for some application to recognize the click
        // see: https://stackoverflow.com/a/2420366/10390454
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event2?.setIntegerValueField(.mouseEventClickState, value: 1)
        // explicitly set flags because clicking while holding a modifier key can alter it's behaviour
        // e.g. CTRL + left click -> right click,
        // Shift + right click -> Nothing in Finder
        // this matters because modifier keys are used to trigger different click types in Hint Mode.
        event?.flags = .init()
        event2?.flags = .init()
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    static func doubleLeftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event?.flags = .init()
        
        event?.post(tap: .cghidEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cghidEventTap)
        
        event?.setIntegerValueField(.mouseEventClickState, value: 2)
        
        event?.type = .leftMouseDown
        event?.post(tap: .cghidEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cghidEventTap)
    }
    
    static func rightClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: position, mouseButton: .right)
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event?.flags = .init()
        
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: position, mouseButton: .right)
        event2?.setIntegerValueField(.mouseEventClickState, value: 1)
        event2?.flags = .init()
        
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    static func getUIElementChildrenRecursive(element: UIElement, parentContainerFrame: NSRect) -> Observable<UIElement> {
        return getAttributes(element: element)
            .flatMap({ attributes -> Observable<UIElement> in
                let (roleOptional, positionOptional, sizeOptional) = attributes
                guard let role = roleOptional,
                    let position = positionOptional,
                    let size = sizeOptional else {
                        return Observable.empty()
                }
                
                var newParentContainerFrame: NSRect?
                
                // ignore subcomponents of a scrollbar
                if role == Role.scrollBar.rawValue {
                    return Observable.empty()
                }
                
                if role == Role.scrollArea.rawValue ||
                    role == Role.row.rawValue ||
                    role == "AXPage" ||
                    role == Role.group.rawValue {
                    newParentContainerFrame = NSRect(origin: position, size: size)
                }
                
                // append to allowed elements list if element's frame intersect with it's parent container's frame.
                let frame = NSRect(origin: position, size: size)
                let includeElement = parentContainerFrame.intersects(frame)
                
                if !includeElement {
                    return Observable.empty()
                }
                
                return getChildren(element: element)
                    .flatMap({ children -> Observable<UIElement> in
                        if children.count <= 0 {
                            return Observable.just(element)
                        }
                        
                        return Utils.eagerConcat(observables: [
                            Observable.just(element),
                            Utils.eagerConcat(observables: 
                                children.map({ getUIElementChildrenRecursive(element: $0, parentContainerFrame: newParentContainerFrame ?? parentContainerFrame) })
                            )
                        ])
                    })
            })
    }
    
    static func getWindowElements(windowElement: UIElement) -> Observable<UIElement> {
        guard let windowSize: NSSize = try? windowElement.attribute(.size),
            let windowPosition: NSPoint = try? windowElement.attribute(.position) else {
                return Observable.empty()
        }
        let windowFrame = NSRect(origin: windowPosition, size: windowSize)
        return Utils.getUIElementChildrenRecursive(element: windowElement, parentContainerFrame: windowFrame)
    }
    
    // eagerConcat behaves like concat but all the observables are fired simultaneously instead of only after the previous ones are completed.
    static func eagerConcat<T>(observables: [Observable<T>]) -> Observable<T> {
        let taggedWithIndex = observables.enumerated().map({ (index, element) in
            return element.map({ (index, $0) })
        })
        let merged = Observable.merge(taggedWithIndex).toArray().asObservable()

        return merged.flatMapLatest({ o -> Observable<T> in
            let sortedO = o
                .sorted(by: { (a, b) in
                    let (i1, _) = a
                    let (i2, _) = b
                    return i1 - i2 < 0
                })
                .map({ (i, e) in e })
            return Observable.from(sortedO)
        })
    }
    
    static func getAttributes(element: UIElement) -> Observable<(String?, NSPoint?, NSSize?)> {
        return getMultipleElementAttribute(element: element, attributes: [.role, .position, .size])
            .map({ valuesOptional in
                guard let values = valuesOptional else {
                    return nil
                }
                do {
                    let role = values[0] as! String?
                    let position = values[1] as! NSPoint?
                    let size = values[2] as! NSSize?
                    return (role, position, size)
                } catch {

                }
                return nil
            })
            .compactMap({ $0 })
    }
    
    static func getMultipleElementAttribute(element: UIElement, attributes: [Attribute]) -> Observable<[Any?]?> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                do {
                    let valueByAttribute = try element.getMultipleAttributes(attributes)
                    let values = attributes.map({ valueByAttribute[$0] })
                    observer.onNext(values)
                } catch {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    static func getElementAttribute<T>(element: UIElement, attribute: Attribute) -> Observable<T?> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                let value: T? = try? element.attribute(attribute)
                observer.onNext(value)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    static func getChildren(element: UIElement) -> Observable<[CachedUIElement]> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                let children: [CachedUIElement] = {
                    let childrenOptional = try? element.attribute(Attribute.children) as [AXUIElement]?;
                    guard let children = childrenOptional else {
                        return []
                    }
                    return children.map({ CachedUIElement($0) })
                }()
                observer.onNext(children)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    static func traverseForMenuBarItems(windowElement: UIElement) -> Observable<UIElement> {
        let application: Observable<UIElement> = getElementAttribute(element: windowElement, attribute: .parent).compactMap({ $0 })
        return application
            .flatMap({ app -> Observable<UIElement> in
                let menuBarObservable: Observable<UIElement?> = getElementAttribute(element: app, attribute: .menuBar)
                return menuBarObservable.compactMap({ $0 })
            })
            .flatMap({ menuBar -> Observable<[CachedUIElement]> in
                return getChildren(element: menuBar)
            })
            .flatMap({ children -> Observable<CachedUIElement> in
                return Observable.from(children)
            })
            .map({ UIElement($0.element) })
    }
    
    static func traverseForExtraMenuBarItems() -> Observable<UIElement> {
        let menuBars = eagerConcat(observables: Application.all()
            .map({ app -> Observable<UIElement> in
                let menuBarOptional: Observable<UIElement?> = getElementAttribute(element: app, attribute: .extrasMenuBar)
                return menuBarOptional.compactMap({ $0 })
            })
        )
        return menuBars
            .flatMap({ menuBar -> Observable<[CachedUIElement]> in
                return getChildren(element: menuBar)
            })
            .flatMap({ menuBarItems -> Observable<CachedUIElement> in
                return Observable.from(menuBarItems)
            })
            .map({ UIElement($0.element) })
    }
    
    static func traverseForNotificationCenterItems() -> Observable<UIElement> {
        let notificationAppOptional = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Notification Centre" })
        guard let notificationApp = notificationAppOptional,
            let notificationAppUIElement = Application(notificationApp) else {
            return Observable.empty()
        }
        
        let windows = (try? notificationAppUIElement.windows()) ?? []
        return eagerConcat(observables: windows.map({ getWindowElements(windowElement: $0 ) }))
    }
    
    // For performance reasons Chromium only makes the webview accessible when there it detects voiceover through the `AXEnhancedUserInterface` attribute on the Chrome application itself:
    // http://dev.chromium.org/developers/design-documents/accessibility
    // Similarly, electron uses `AXManualAccessibility`:
    // https://electronjs.org/docs/tutorial/accessibility#assistive-technology
    // AXEnhancedUserInterface breaks window managers, so it's removed for now.
    static func setAccessibilityAttributes(app: UIElement) {
//        do {
//            try app.setAttribute("AXEnhancedUserInterface", value: true)
//        } catch {
//
//        }
        _ = try? app.setAttribute("AXManualAccessibility", value: true)
    }
    
    static func getCurrentApplicationWindowManually() -> UIElement? {
        guard let nsApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let appOptional = Application.init(nsApplication)
        if let app = appOptional {
            Utils.setAccessibilityAttributes(app: app)
        }
        
        return try? appOptional?.attribute(.focusedWindow)
    }
}
