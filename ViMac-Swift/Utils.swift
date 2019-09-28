//
//  Utils.swift
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
    
    static func traverseUIElementForPressables(rootElement: UIElement) -> [UIElement]? {
        let windowFrameOptional: NSRect? = {
            do {
                return try rootElement.attribute(.frame)
            } catch {
                return nil
            }
        }()
        
        guard let windowFrame = windowFrameOptional else {
            return nil
        }
        
        var elements = [UIElement]()
        func fn(element: UIElement, level: Int) -> Void {
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
            
            if let role = roleOptional {
                // ignore subcomponents of a scrollbar
                if role == Role.scrollBar.rawValue {
                    return
                }
                
                // ignore rows that are out of window frame
                // doing this improves traversal speed significantly because we do not look at
                // children elements that most likely are out of frame
                if role == Role.row.rawValue || role == "AXPage" {
                    if let position = positionOptional {
                        if (!windowFrame.contains(position)) {
                            return
                        }
                    } else {
                        return
                    }
                }
            }

            if let position = positionOptional {
                if (windowFrame.contains(position)) {
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
            
            children.forEach { child in
                fn(element: UIElement(child), level: level + 1)
            }
        }
        fn(element: rootElement, level: 1)
        return elements
    }
    
    static func traverseForMenuBarItems(windowElement: UIElement) -> [UIElement] {
        var menuBarItems = [UIElement]()
        let applicationOptional: UIElement? = {
            do {
                return try! windowElement.attribute(.parent)
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
}
