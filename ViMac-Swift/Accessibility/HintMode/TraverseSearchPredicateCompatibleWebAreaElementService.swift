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
    let tree: ElementTree
    let element: Element
    let parent: Element?
    let app: NSRunningApplication
    let windowElement: Element
    let clipBounds: NSRect?
    
    required init(tree: ElementTree, element: Element, parent: Element?, app: NSRunningApplication, windowElement: Element, clipBounds: NSRect?) {
        self.tree = tree
        self.element = element
        self.parent = parent
        self.app = app
        self.windowElement = windowElement
        self.clipBounds = clipBounds
    }
    
    func perform() {
        if !isElementVisible() {
            return
        }
        
        element.setClippedFrame(elementClipBounds())
        
        if !tree.insert(element, parentId: parent?.rawElement) { return }

        let children: [Element]? = try? getRecursiveChildrenThroughSearchPredicate()

        var visibleChildren: [Element] = []
        for child in children ?? [] {
            let clipBounds = elementClipBounds().intersection(child.frame)
            if (!clipBounds.isEmpty) {
                child.setClippedFrame(clipBounds)
                visibleChildren.append(child)
            }
        }

        for child in visibleChildren {
            if !tree.insert(child, parentId: self.element.rawElement) { continue }
        }
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
    
    private func getRecursiveChildrenThroughSearchPredicate() throws -> [Element]? {
        var query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": "AXAnyTypeSearchKey"
        ]
        
        let searchKeys = [
            "AXButtonSearchKey",
            "AXCheckBoxSearchKey",
            "AXControlSearchKey",
            "AXGraphicSearchKey",
            "AXLinkSearchKey",
            "AXRadioGroupSearchKey",
            "AXTextFieldSearchKey"
        ]
        
        if app.bundleIdentifier == "com.apple.Safari" || app.bundleIdentifier == "com.google.Chrome.canary" {
            query["AXSearchKey"] = searchKeys
        }
        
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: query)
        let elements = rawElements?
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
        return elements
    }
}
