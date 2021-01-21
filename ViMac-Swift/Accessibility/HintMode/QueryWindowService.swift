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
    let app: NSRunningApplication
    let window: Element
    
    init(app: NSRunningApplication, window: Element) {
        self.app = app
        self.window = window
    }
    
    func perform() throws -> [Element] {
        let children = try getChildren()
        let childrenNodes = children?.map { child -> ElementTreeNode? in
            TraverseElementServiceFinder
                .init(app: app, element: child).find()
                .init(element: child, app: app, windowElement: window, containerElement: nil).perform()
        }
        
        var elements: [Element] = []
        for childNode in childrenNodes ?? [] {
            if let childNode = childNode {
                elements.append(contentsOf: flattenElementTreeNode(node: childNode))
            }
        }
        
        print(elements.count)
        
        return elements
    }
    
    private func getChildren() throws -> [Element]? {
        let rawElements: [AXUIElement]? = try UIElement(window.rawElement).attribute(.children)
        return rawElements?
            .map { Element.initialize(rawElement: $0) }
            .compactMap({ $0 })
    }
    
    private func flattenElementTreeNode(node: ElementTreeNode) -> [Element] {
        FlattenElementTreeNode(node).perform()
    }
}

class FlattenElementTreeNode {
    let root: ElementTreeNode
    var result: [Element] = []

    init(_ root: ElementTreeNode) {
        self.root = root
    }
    
    func perform() -> [Element] {
        flatten(root)
        return result
    }
    
    private func flatten(_ node: ElementTreeNode) {
        if node.isHintable() {
            result.append(node.root)
        }
        
        let children = node.children ?? []
        for child in children {
            flatten(child)
        }
    }
}
