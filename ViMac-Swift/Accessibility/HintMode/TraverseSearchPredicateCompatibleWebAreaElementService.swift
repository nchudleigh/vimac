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
    
    // use search predicates to query for web area children elements
    // Note: There is a difference in implementation of search keys for Chromium and WebKit,
    // hence the need to have different approaches "one-shot with all search keys" (WebKit) vs "multiple-shots with a single search key" (Chromium)
    // Chromium has fixed their implementation to act like WebKit, but current versions (~90.0) need this workaround.
    // https://chromium-review.googlesource.com/c/chromium/src/+/2773520
    private func getRecursiveChildrenThroughSearchPredicate() throws -> [Element]? {
        let query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true
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
        
        var multiSearchKeyQuery = query
        multiSearchKeyQuery["AXSearchKey"] = searchKeys
        
        let multiSearchKeyQueryMatches: Int = (try UIElement(element.rawElement).parameterizedAttribute("AXUIElementCountForSearchPredicate", param: multiSearchKeyQuery)) ?? 0
        
        if multiSearchKeyQueryMatches > 0 {
            let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: multiSearchKeyQuery)
            let elements = rawElements?
                .map({ Element.initialize(rawElement: $0) })
                .compactMap({ $0 })
            return elements
        }
        
        var elements: [AXUIElement] = []
        for searchKey in searchKeys {
            var singleSearchKeyQuery = query
            singleSearchKeyQuery["AXSearchKey"] = searchKey
            if let rawElements: [AXUIElement] = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: singleSearchKeyQuery) {
                elements.append(contentsOf: rawElements)
            }
        }
        
        let uniqueElements = elements.uniqued()
        
        return uniqueElements
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
    }
}

// https://stackoverflow.com/a/25739498
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
