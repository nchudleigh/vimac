//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import MASShortcut

class Utils: NSObject {
    static let defaultCommandShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .shift])
    static let commandShortcutKey = "CommandShortcut"
    static let scrollSensitivityKey = "ScrollSensitivity"
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Utils.scrollSensitivityKey: 20
        ])
    }
    
    // This function returns the position of the point after the y-axis is flipped.
    // We need this because accessing the position of a AXUIElement gives us the position from top-left,
    // but the coordinate system in macOS starts from bottom-left.
    // https://developer.apple.com/documentation/applicationservices/kaxpositionattribute?language=objc
    static func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        // cannot use NSScreen.main because the height of the global coordinate system can be larger
        // see: https://stackoverflow.com/a/45289010/10390454
        let screenHeight = NSScreen.screens.map { $0.frame.origin.y + $0.frame.height }.max()!
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
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    static func doubleLeftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        
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
        
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: position, mouseButton: .right)
        event2?.setIntegerValueField(.mouseEventClickState, value: 1)
        
        event?.post(tap: .cghidEventTap)
        event2?.post(tap: .cghidEventTap)
    }
    
    static func traverseUIElementForPressables(rootElement: UIElement) -> [UIElement] {
        var elements = [UIElement]()
        func fn(element: UIElement, parentScrollAreaFrame: NSRect?, level: Int) -> Void {
            let roleOptional: String? = {
                do {
                    return try element.attribute(.role)
                } catch {
                    return nil
                }
            }()

            let positionOptional: NSPoint? = {
                do {
                    return try element.attribute(.position)
                } catch {
                    return nil
                }
            }()
            
            let sizeOptional: NSSize? = {
                do {
                    return try element.attribute(.size)
                } catch {
                    return nil
                }
            }()
            
            var newScrollAreaFrame: NSRect? = nil
            var isScrollArea = false
            
            if let role = roleOptional {
                // ignore subcomponents of a scrollbar
                if role == Role.scrollBar.rawValue {
                    return
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
                                return
                            }
                        }
                    } else {
                        return
                    }
                }
            }

            // append to allowed elements list if
            // 1. element's role is not blacklisted
            // 2. element does not have a parent scroll area, but if it does both frames must intersect
            if let position = positionOptional,
                let size = sizeOptional,
                let role = roleOptional {
                let frame = NSRect(origin: position, size: size)
                if let parentScrollAreaFrame = parentScrollAreaFrame {
                    if parentScrollAreaFrame.intersects(frame) {
                        elements.append(element)
                    }
                } else {
                    elements.append(element)
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
            
            for child in children {
                if isScrollArea {
                    fn(element: UIElement(child), parentScrollAreaFrame: newScrollAreaFrame, level: level + 1)
                } else {
                    fn(element: UIElement(child), parentScrollAreaFrame: parentScrollAreaFrame, level: level + 1)
                }
            }
        }
        fn(element: rootElement, parentScrollAreaFrame: nil, level: 1)
        return elements
    }
    
    static func traverseForMenuBarItems(windowElement: UIElement) -> [UIElement] {
        var menuBarItems = [UIElement]()
        let applicationOptional: UIElement? = {
            do {
                return try windowElement.attribute(.parent)
            } catch {
                return nil
            }
        }()
        
        if let application = applicationOptional {
            do {
                let menuBar: UIElement? = try application.attribute(.menuBar)
                let menuBarChildrenNative: [AXUIElement]? = try menuBar?.attribute(.children)
                let menuBarChildrenOptional = menuBarChildrenNative?.map { UIElement($0) }
                if let menuBarChildren = menuBarChildrenOptional {
                    menuBarItems.append(contentsOf: menuBarChildren)
                }
            } catch {
            }
        }
        return menuBarItems
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
    
    static func mapArgRoleToAXRole(arg: ElementSelectorArg) -> [Role] {
        if arg == .button {
            return [Role.button, Role.menuButton, Role.radioButton, Role.popUpButton, Role.checkBox]
        }
        
        if arg == .group {
            return [Role.group, Role.tabGroup, Role.radioGroup, Role.splitGroup]
        }
        
        if arg == .disclosureTriangle {
            return [Role.disclosureTriangle]
        }
        
        if arg == .row {
            return [Role.row]
        }
	
        if arg == .image {
            return [Role.image]
        }
        
        if arg == .text {
            return [Role.textField, Role.textArea, Role.staticText]
        }
        
        if arg == .link {
            return [Role.link]
        }
        
        return []
    }
    
    static func setAccessibilityAttributes(app: UIElement) {
        do {
            try app.setAttribute("AXEnhancedUserInterface", value: true)
        } catch {

        }
        do {
            try app.setAttribute("AXManualAccessibility", value: true)
        } catch {

        }
    }
}
