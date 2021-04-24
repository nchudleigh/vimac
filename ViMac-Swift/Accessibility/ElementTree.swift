//
//  ElementTree.swift
//  Vimac
//
//  Created by Dexter Leng on 30/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

class ElementTree {
    private var elementsById: [AXUIElement : Element]
    private var childrenById: [AXUIElement : [AXUIElement]]
    private var rootId: AXUIElement?
    
    private var cachedHintableChildrenCountById: [AXUIElement : Int]?
    
    init() {
        elementsById = [:]
        childrenById = [:]
    }
    
    func insert(_ element: Element, parentId: AXUIElement?) -> Bool {
        let isRoot = parentId == nil

        if find(element.rawElement) != nil { return false }
        if let parentId = parentId {
            if find(parentId) == nil { return false }
        }
        
        if isRoot {
            if self.rootId != nil { return false }
            self.rootId = element.rawElement
        }

        elementsById[element.rawElement] = element
        
        if let parentId = parentId {
            addChild(parentId, childId: element.rawElement)
        }

        return true
    }
    
    private func addChild(_ id: AXUIElement, childId: AXUIElement) {
        guard let _ = find(id),
              let _ = find(childId) else { return }
        
        if childrenById[id] == nil {
            childrenById[id] = []
        }
        
        childrenById[id]!.append(childId)
    }
    
    func find(_ id: AXUIElement) -> Element? {
        elementsById[id]
    }
    
    func query() -> [Element]? {
        if rootId == nil { return nil }
        self.cachedHintableChildrenCountById = [:]
        
        var results: [Element] = []
        var stack: [Element] = [elementsById[rootId!]!]
        
        while let element = stack.popLast() {
            if element.role == "AXMenu" {
                results = self.children(element.rawElement) ?? []
                break
            }
            
            if isHintable(element) {
                results.append(element)
            }
            
            let children = self.children(element.rawElement)
            for child in (children ?? []) {
                stack.append(child)
            }
        }
        
        return results
    }
    
    func children(_ id: AXUIElement) -> [Element]? {
        guard let childIds = childrenById[id] else { return nil }
        return childIds.map { elementsById[$0]! }
    }
    
    private func isHintable(_ element: Element) -> Bool {
        if element.role == "AXWindow" || element.role == "AXScrollArea" {
            return false
        }
        
        return isActionable(element) || isRowWithoutHintableChildren(element)
    }
    
    private func isActionable(_ element: Element) -> Bool {
        let ignoredActions: Set = [
            "AXShowMenu",
            "AXScrollToVisible",
            "AXShowDefaultUI",
            "AXShowAlternateUI"
        ]
        let actions = Set(element.actions).subtracting(ignoredActions)
        return actions.count > 0
    }
    
    private func isRowWithoutHintableChildren(_ element: Element) -> Bool {
         element.role == "AXRow" && hintableChildrenCount(element) == 0
    }
    
    private func hintableChildrenCount(_ element: Element) -> Int {
        if self.cachedHintableChildrenCountById == nil {
            fatalError()
        }
        
        if let hintableChildrenCount = cachedHintableChildrenCountById![element.rawElement] {
            return hintableChildrenCount
        }

        let children = self.children(element.rawElement) ?? []
        let hintableChildrenCount = children
            .map { self.hintableChildrenCount($0) + (isHintable($0) ? 1 : 0) }
            .reduce(0, +)
        
        self.cachedHintableChildrenCountById![element.rawElement] = hintableChildrenCount
        return hintableChildrenCount
    }
}
