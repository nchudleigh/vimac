//
//  TraverseRowContainingElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class TraverseRowContainingElementService: TraverseElementService {
    let element: Element
    
    required init(element: Element) {
        self.element = element
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
            .init(element: element).perform()
    }
    
    private func getVisibleChildren(_ element: Element) throws -> [Element]? {
        try getChildren(element)?.filter({ child in
            element.frame.intersects(child.frame)
        })
    }
    
    private func getChildren(_ element: Element) throws -> [Element]? {
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).attribute(.visibleRows)
        return rawElements?
            .map { Element.initialize(rawElement: $0) }
            .compactMap({ $0 })
    }
}
