//
//  TraverseWebAreaElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

import Cocoa
import AXSwift

class TraverseWebAreaElementService : TraverseElementService {
    let element: Element
    let parent: Element
    
    required init(element: Element, parent: Element) {
        self.element = element
        self.parent = parent
    }
    
    func perform() -> ElementTreeNode? {
        if !element.frame.intersects(parent.frame) {
            return nil
        }
        
        if !supportsChildrenThroughSearchPredicate() {
            return TraverseGenericElementService.init(element: element, parent: parent).perform()
        }
        
        let recursiveChildren = try? getRecursiveChildrenThroughSearchPredicate()
        let recursiveChildrenNodes = recursiveChildren?.map { childOptional -> ElementTreeNode? in
            guard let child = childOptional else { return nil }
            return ElementTreeNode(root: child, children: nil)
        }
        return ElementTreeNode(root: element, children: recursiveChildrenNodes)
    }
    
    private func getChildren() throws -> [Element?]? {
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).attribute(.children)
        return rawElements?.map { Element.initialize(rawElement: $0) }
    }
    
    private func supportsChildrenThroughSearchPredicate() -> Bool {
        let parameterizedAttrs = try? UIElement(element.rawElement).parameterizedAttributesAsStrings()
        return parameterizedAttrs?.contains("AXUIElementsForSearchPredicate") ?? false
    }
    
    private func getRecursiveChildrenThroughSearchPredicate() throws -> [Element?]? {
        let query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": "AXAnyTypeSearchKey"
        ]
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).parameterizedAttribute("AXUIElementsForSearchPredicate", param: query)
        let elements = rawElements?.map({ Element.initialize(rawElement: $0) })
        return elements
    }
}
