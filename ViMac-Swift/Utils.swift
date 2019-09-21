//
//  Utils.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class Utils: NSObject {
    // This function returns the position of the point after the y-axis is flipped.
    // We need this because accessing the position of a AXUIElement gives us the position from top-left,
    // but the coordinate system in macOS starts from bottom-left.
    // https://developer.apple.com/documentation/applicationservices/kaxpositionattribute?language=objc
    static func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        let screenHeight = NSScreen.screens.first?.frame.size.height
        return CGPoint(x: point.x, y: screenHeight! - size.height - point.y)
    }
    
    static func moveMouse(position: CGPoint) {
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)
        moveEvent?.post(tap: .cgSessionEventTap)
    }
    
    static func leftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        event?.post(tap: .cgSessionEventTap)
        event2?.post(tap: .cgSessionEventTap)
    }
    
    static func traverseUIElementForPressables(rootElement: UIElement) -> [UIElement] {
        var elements = [UIElement]()
        func fn(element: UIElement, level: Int) -> Void {
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
                    return
                }
            }
            
            if let actions = actionsOptional {
                if (actions.count > 0) {
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
}
