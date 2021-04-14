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
        
        element.setClippedFrame(elementClippedBounds())

        if !tree.insert(element, parentId: parent?.rawElement) { return }
        
        let children: [Element]? = try? getChildren(element)

        children?.forEach { child in
            traverseElement(child)
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
    
    private func elementClippedBounds() -> NSRect {
        if let clipBounds = clipBounds {
            return clipBounds.intersection(element.frame)
        }
        return element.frame
    }
    
    private func traverseElement(_ element: Element) {
        TraverseElementServiceFinder
            .init(app: app, element: element).find()
            .init(tree: tree, element: element, parent: self.element, app: app, windowElement: windowElement, clipBounds: elementClippedBounds()).perform()
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
