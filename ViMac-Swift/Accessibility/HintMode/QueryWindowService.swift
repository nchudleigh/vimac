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
        let childrenNodes = children?.map { child -> ElementTreeNode? in
            TraverseElementServiceFinder
                .init(child).find()
                .init(element: child, windowElement: windowElement, containerElement: nil).perform()
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
        let rawElements: [AXUIElement]? = try UIElement(windowElement.rawElement).attribute(.children)
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
        switch node {
        case .generic(let element, let children):
            return _flatten(element: element, children: children ?? [])
        case .webArea(let webArea, let elements, let usedSearchKeys):
            return _flattenWebArea(webArea: webArea, elements: elements ?? [], usedSearchKeys: usedSearchKeys)
        }
    }
    
    private func _flatten(element: Element, children: [ElementTreeNode]) -> Int {
        let childrenHintableElements = children
            .map { flatten($0) }
            .reduce(0, +)
        
        let ignoredActions: Set = [
            "AXShowMenu",
            "AXScrollToVisible",
        ]
        let actions = Set(element.actions).subtracting(ignoredActions)
        
        let isActionable = actions.count > 0
        let isRowWithoutActionableChildren = childrenHintableElements == 0 && element.role == "AXRow"
        let isHintable = isActionable || isRowWithoutActionableChildren
        
        if isHintable {
            result.append(element)
            return childrenHintableElements + 1
        }
        
        return childrenHintableElements
    }
    
    private func _flattenWebArea(webArea: Element, elements: [Element], usedSearchKeys: Bool) -> Int {
        if usedSearchKeys {
            for e in elements {
                result.append(e)
            }
            return elements.count
        }
        
        
        let ignoredActions: Set = [
            "AXShowMenu",
            "AXScrollToVisible",
        ]
        
        let hintableElements = elements.filter { element in
        let actions = Set(element.actions).subtracting(ignoredActions)
        let isActionable = actions.count > 0
            return isActionable
        }
        
        for e in hintableElements {
            result.append(e)
        }
        
        return hintableElements.count
    }
}
