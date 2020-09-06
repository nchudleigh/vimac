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
    let parent: Element
    
    required init(element: Element, parent: Element) {
        self.element = element
        self.parent = parent
    }
    
    func perform() -> ElementTreeNode? {
        if !element.frame.intersects(parent.frame) {
            return nil
            
        }

        let children: [Element]? = try? getChildren(element)?.compactMap({ $0 })

        let childrenNodes = children?.map { child in
            return TraverseElementServiceFinder
                    .init(child).find()
                    .init(element: child, parent: element).perform()
        }
        
        return ElementTreeNode.init(root: element, children: childrenNodes)
    }
    
    private func getChildren(_ element: Element) throws -> [Element?]? {
        let rawElements: [AXUIElement]? = try UIElement(element.rawElement).attribute(.children)
        return rawElements?.map { Element.initialize(rawElement: $0) }
    }
}
