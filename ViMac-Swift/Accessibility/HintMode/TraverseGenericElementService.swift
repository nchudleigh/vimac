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
    let containerElement: Element?
    
    lazy var childContainerElement = computeChildContainerElement()
    
    required init(element: Element, app: NSRunningApplication, windowElement: Element, containerElement: Element?) {
        self.element = element
        self.app = app
        self.windowElement = windowElement
        self.containerElement = containerElement
    }
    
    func perform() -> ElementTreeNode {
        let children: [Element]? = try? getVisibleChildren(element)

        let childrenNodes = children?
            .map { traverseElement($0) }
            .compactMap({ $0 })

        return ElementTreeNode.init(root: element, children: childrenNodes)
    }
    
    private func traverseElement(_ element: Element) -> ElementTreeNode? {
        TraverseElementServiceFinder
            .init(element).find()
            .init(element: element, app: app, windowElement: windowElement, containerElement: childContainerElement).perform()
    }
    
    private func computeChildContainerElement() -> Element? {
        let containerRoles = [
            Role.scrollArea.rawValue,
            Role.row.rawValue,
            "AXPage",
        ]

        if containerRoles.contains(element.role) || element.role.lowercased().contains("group") {
            return element
        }

        return containerElement
    }
    
    private func getVisibleChildren(_ element: Element) throws -> [Element]? {
        try getChildren(element)?.filter({ child in
            (childContainerElement?.frame.intersects(child.frame) ?? true) &&
                child.frame.intersects(windowElement.frame)
        })
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
