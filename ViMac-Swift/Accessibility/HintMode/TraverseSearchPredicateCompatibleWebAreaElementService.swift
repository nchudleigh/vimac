//
//  TraverseWebAreaElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class TraverseSearchPredicateCompatibleWebAreaElementService : TraverseElementService {
    let element: Element
    let app: NSRunningApplication
    let windowElement: Element
    let clipBounds: NSRect?
    
    required init(element: Element, app: NSRunningApplication, windowElement: Element, clipBounds: NSRect?) {
        self.element = element
        self.app = app
        self.windowElement = windowElement
        self.clipBounds = clipBounds
    }
    
    func perform() -> ElementTreeNode? {
        if !isElementVisible() {
            return nil
        }
        
        element.setClippedFrame(elementClipBounds())
        
        let children: [Element]? = {
            if isSafari() {
                return try? getRecursiveChildrenThroughSearchPredicateWithSearchKeys()
            }
            return try? getRecursiveChildrenThroughSearchPredicate()
        }()

        var visibleChildren: [Element] = []
        for child in children ?? [] {
            let clipBounds = elementClipBounds().intersection(child.frame)
            if (!clipBounds.isEmpty) {
                child.setClippedFrame(clipBounds)
                visibleChildren.append(child)
            }
        }

        let recursiveChildrenNodes = visibleChildren
            .map { ElementTreeNode(root: $0, children: nil) }
        return ElementTreeNode(root: element, children: recursiveChildrenNodes)
    }
    
    private func isElementVisible() -> Bool {
        if let clipBounds = clipBounds {
            if !clipBounds.intersects(element.frame) {
                return false
            }
        }
        return true
    }
    
    private func elementClipBounds() -> NSRect {
        if let clipBounds = clipBounds {
            return clipBounds.intersection(element.frame)
        }
        return element.frame
    }
    
    private func isSafari() -> Bool {
        app.bundleIdentifier == "com.apple.Safari"
    }
    
    private func getRecursiveChildrenThroughSearchPredicate() throws -> [Element]? {
        let query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": "AXAnyTypeSearchKey"
        ]
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: query)
        let elements = rawElements?
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
        return elements
    }
    
    private func getRecursiveChildrenThroughSearchPredicateWithSearchKeys() throws -> [Element]? {
        let query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": [
                "AXButtonSearchKey",
                "AXCheckBoxSearchKey",
                "AXControlSearchKey",
                "AXGraphicSearchKey",
                "AXLinkSearchKey",
                "AXRadioGroupSearchKey",
                "AXTextFieldSearchKey"
            ]
        ]
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: query)
        let elements = rawElements?
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
        return elements
    }
}
