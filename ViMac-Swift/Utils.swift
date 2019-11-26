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
    static let scrollSensitivityKey = "ScrollSensitivity"
    static let isVerticalScrollReversedKey = "IsVerticalScrollReversed"
    static let isHorizontalScrollReversedKey = "IsHorizontalScrollReversed"
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Utils.scrollSensitivityKey: 20,
            Utils.isVerticalScrollReversedKey: false,
            Utils.isHorizontalScrollReversedKey: false,
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
    
    static func getUIElementChildrenRecursive(element: UIElement, parentScrollAreaFrame: NSRect?) -> Observable<UIElement> {
        return getAttributes(element: element)
            .flatMap({ attributes -> Observable<UIElement> in
                let (roleOptional, positionOptional, sizeOptional, children) = attributes
                
                var newScrollAreaFrame: NSRect? = nil
                var isScrollArea = false
                
                if let role = roleOptional {
                    // ignore subcomponents of a scrollbar
                    if role == Role.scrollBar.rawValue {
                        return Observable.empty()
                    }
                    
                    if role == Role.scrollArea.rawValue {
                        isScrollArea = true
                        if let position = positionOptional,
                            let size = sizeOptional {
                            let frame = NSRect(origin: position, size: size)
                            newScrollAreaFrame = frame
                        }
                    }
                    
                    // ignore rows that are out of parent scroll area's frame
                    // doing this improves traversal speed significantly because we do not look at
                    // children elements that most likely are out of frame
                    if role == Role.row.rawValue || role == "AXPage" || role == Role.group.rawValue {
                        if let position = positionOptional,
                            let size = sizeOptional {
                            let frame = NSRect(origin: position, size: size)
                            if let scrollAreaFrame = parentScrollAreaFrame {
                                if (!scrollAreaFrame.intersects(frame)) {
                                    return Observable.empty()
                                }
                            }
                        } else {
                            return Observable.empty()
                        }
                    }
                }

                var includeElement = false
                
                // append to allowed elements list if
                // 1. element's role is not blacklisted
                // 2. element does not have a parent scroll area, but if it does both frames must intersect
                if let position = positionOptional,
                    let size = sizeOptional,
                    let role = roleOptional {
                    let frame = NSRect(origin: position, size: size)
                    if let parentScrollAreaFrame = parentScrollAreaFrame {
                        if parentScrollAreaFrame.intersects(frame) {
                            includeElement = true
                        }
                    } else {
                        includeElement = true
                    }
                }
                
                let psaf = isScrollArea ? newScrollAreaFrame : parentScrollAreaFrame
                
                return Observable.just(children)
                    .flatMap({ children -> Observable<UIElement> in
                        if children.count <= 0 {
                            return Observable.just(element)
                        }
                        
                        return Observable.merge([
                            includeElement ? Observable.just(element) : Observable.empty(),
                            Observable.merge(
                                children.map({ getUIElementChildrenRecursive(element: $0, parentScrollAreaFrame: psaf) })
                            )
                        ])
                    })
            })
    }
    
    static func getAttributes(element: UIElement) -> Observable<(String?, NSPoint?, NSSize?, [UIElement])> {
        return getMultipleElementAttribute(element: element, attributes: [.role, .position, .size, .children])
            .map({ valuesOptional in
                guard let values = valuesOptional else {
                    return nil
                }
                do {
                    let role = values[0] as! String?
                    let position = values[1] as! NSPoint?
                    let size = values[2] as! NSSize?
                    let children = (values[3] as! [AXUIElement]? ?? []).map({ CachedUIElement($0) })
                    return (role, position, size, children)
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
                let value: T? = {
                    do {
                        return try element.attribute(attribute)
                    } catch {
                        return nil
                    }
                }()
                observer.onNext(value)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    static func getChildren(element: UIElement) -> Observable<[UIElement]> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                let children: [UIElement] = {
                    do {
                        let childrenOptional = try element.attribute(Attribute.children) as [AXUIElement]?;
                        guard let children = childrenOptional else {
                            return []
                        }
                        return children.map({ UIElement($0) })
                    } catch {
                        return []
                    }
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
            .flatMap({ menuBar -> Observable<[UIElement]> in
                return getChildren(element: menuBar)
            })
            .flatMap({ children -> Observable<UIElement> in
                return Observable.from(children)
            })
    }
    
    static func traverseUIElementForScrollAreas(rootElement: UIElement) -> [UIElement] {
        var elements = [UIElement]()
        func fn(element: UIElement, level: Int) -> Void {
            let roleOptional: String? = {
                do {
                    return try element.attribute(.role)
                } catch {
                    return nil
                }
            }()
            
            if let role = roleOptional {
                if role == Role.scrollArea.rawValue {
                    elements.append(element)
                    return
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
            
            children.forEach { child in
                fn(element: UIElement(child), level: level + 1)
            }
        }
        fn(element: rootElement, level: 1)
        return elements
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
        do {
            try app.setAttribute("AXManualAccessibility", value: true)
        } catch {

        }
    }
    
    static func getCurrentApplicationWindowManually() -> UIElement? {
        guard let nsApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let appOptional = Application.init(nsApplication)
        if let app = appOptional {
            Utils.setAccessibilityAttributes(app: app)
        }
        
        return {
            do {
                return try appOptional?.attribute(.focusedWindow)
            } catch {
                return nil
            }
        }()
    }
}
