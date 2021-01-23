//
//  TraverseGenericElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class TraverseGenericElementService : TraverseElementService {
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
        
        element.setClippedFrame(elementClippedBounds())
        
        let children: [Element]? = try? getChildren(element)

        let childrenNodes = children?
            .map { traverseElement($0) }
            .compactMap({ $0 })

        return ElementTreeNode.init(root: element, children: childrenNodes)
    }
    
    private func isElementVisible() -> Bool {
        if let clipBounds = clipBounds {
            if !clipBounds.intersects(element.frame) {
                return false
            }
        }
        return true
    }
    
    private func elementClippedBounds() -> NSRect {
        if let clipBounds = clipBounds {
            return clipBounds.intersection(element.frame)
        }
        return element.frame
    }
    
    private func traverseElement(_ element: Element) -> ElementTreeNode? {
        TraverseElementServiceFinder
            .init(app: app, element: element).find()
            .init(element: element, app: app, windowElement: windowElement, clipBounds: elementClippedBounds()).perform()
    }

    private func getChildren(_ element: Element) throws -> [Element]? {
        let rawElements: [AXUIElement]? = try {
            if element.role == "AXTable" || element.role == "AXOutline" {
                return try UIElement(element.rawElement).attribute(.visibleRows)
            }
            return try UIElement(element.rawElement).attribute(.children)
        }()
        return rawElements?
            .map { Element.initialize(rawElement: $0) }
            .compactMap({ $0 })
    }
}
