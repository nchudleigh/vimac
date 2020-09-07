//
//  QueryWindowService.swift
//  Vimac
//
//  Created by Dexter Leng on 28/8/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class QueryWindowService {
    let windowElement: Element
    
    init(windowElement: Element) {
        self.windowElement = windowElement
    }
    
    func perform() throws -> [Element] {
        let children = try getChildren()
        let childrenNodes = children?.map { childOptional -> ElementTreeNode? in
            guard let child = childOptional else { return nil }
            
            return TraverseElementServiceFinder
                    .init(child).find()
                    .init(element: child).perform()
        }
        
        var elements: [Element] = []
        for childNode in childrenNodes ?? [] {
            if let childNode = childNode {
                elements.append(contentsOf: flattenElementTreeNode(node: childNode))
            }
        }
        
        return elements
    }
    
    private func getChildren() throws -> [Element?]? {
        let rawElements: [AXUIElement]? = try UIElement(windowElement.rawElement).attribute(.children)
        return rawElements?.map { Element.initialize(rawElement: $0) }
    }
    
    private func flattenElementTreeNode(node: ElementTreeNode) -> [Element] {
        var elements: [Element] = []
        var stack = [node]
        while stack.count > 0 {
            let head = stack.popLast()!
            elements.append(head.root)
            
            for child in head.children ?? [] {
                stack.append(child)
            }
        }
        return elements
    }
}
