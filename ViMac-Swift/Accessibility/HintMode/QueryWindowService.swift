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
    
    private func flatten(_ node: ElementTreeNode) -> Int {
        let children = node.children ?? []
        let childrenHintableElements = children
            .map { flatten($0) }
            .reduce(0, +)
        
        let ignoredActions: Set = [
            "AXShowMenu",
            "AXScrollToVisible",
        ]
        let actions = Set(node.root.actions).subtracting(ignoredActions)
        
        let isActionable = actions.count > 0
        let isRowWithoutActionableChildren = childrenHintableElements == 0 && node.root.role == "AXRow"
        let isHintable = isActionable || isRowWithoutActionableChildren
        
        if isHintable {
            result.append(node.root)
            return childrenHintableElements + 1
        }
        
        return childrenHintableElements
    }
}
