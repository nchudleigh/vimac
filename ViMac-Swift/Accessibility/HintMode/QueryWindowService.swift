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
        let elementTree = TraverseElementServiceFinder
            .init(app: app, element: window).find()
            .init(element: window, app: app, windowElement: window, containerElement: nil).perform()
        
        let elements: [Element] = {
            if let elementTree = elementTree { return flattenElementTreeNode(node: elementTree) }
            return []
        }()
        return elements
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
