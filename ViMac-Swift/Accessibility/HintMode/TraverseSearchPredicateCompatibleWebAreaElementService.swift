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
        let queryAnySearchKey: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": "AXAnyTypeSearchKey"
        ]
        
        var queryWithSearchKeys = queryAnySearchKey
        queryWithSearchKeys["AXSearchKey"] = [
            "AXButtonSearchKey",
            "AXCheckBoxSearchKey",
            "AXControlSearchKey",
            "AXGraphicSearchKey",
            "AXLinkSearchKey",
            "AXRadioGroupSearchKey",
            "AXTextFieldSearchKey"
        ]
        
        let queryToUse: [String : Any] = {
            let searchKeysCount: Int = (try? UIElement(element.rawElement).parameterizedAttribute("AXUIElementCountForSearchPredicate", param: queryWithSearchKeys)) ?? 0
            return searchKeysCount == 0 ? queryAnySearchKey : queryWithSearchKeys
        }()
        
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: queryToUse)
        let elements = rawElements?
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
        return elements
    }
}
