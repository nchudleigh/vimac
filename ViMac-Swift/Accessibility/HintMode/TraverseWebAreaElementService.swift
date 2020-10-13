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
    let windowElement: Element
    let containerElement: Element?
    
    required init(element: Element, windowElement: Element, containerElement: Element?) {
        self.element = element
        self.windowElement = windowElement
        self.containerElement = containerElement
    }
    
    func perform() -> ElementTreeNode {
        if !supportsChildrenThroughSearchPredicate() {
            return TraverseGenericElementService.init(element: element, windowElement: windowElement, containerElement: containerElement).perform()
        }
        
        let recursiveChildren = try? getRecursiveChildrenThroughSearchPredicate()
        let recursiveChildrenNodes = recursiveChildren?
            .map { ElementTreeNode(root: $0, children: nil) }
        return ElementTreeNode(root: element, children: recursiveChildrenNodes)
    }
    
    private func supportsChildrenThroughSearchPredicate() -> Bool {
        let parameterizedAttrs = try? UIElement(element.rawElement).parameterizedAttributesAsStrings()
        return parameterizedAttrs?.contains("AXUIElementsForSearchPredicate") ?? false
    }
    
    private func getRecursiveChildrenThroughSearchPredicate() throws -> [Element]? {
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
                "AXStaticTextSearchKey",
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
