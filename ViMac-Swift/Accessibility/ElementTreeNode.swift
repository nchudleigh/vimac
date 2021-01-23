//
//  ElementTreeNode.swift
//  Vimac
//
//  Created by Dexter Leng on 23/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa


class ElementTreeNode {
    let root: Element
    let children: [ElementTreeNode]?
    private var cachedHintableChildrenCount: Int?
    
    init(root: Element, children: [ElementTreeNode]?) {
        self.root = root
        self.children = children
    }
    
    func isHintable() -> Bool {
        if root.role == "AXWindow" {
            return false
        }
        
        return isActionable() || isRowWithoutHintableChildren()
    }
    
    private func isActionable() -> Bool {
        let ignoredActions: Set = [
            "AXShowMenu",
            "AXScrollToVisible",
        ]
        let actions = Set(root.actions).subtracting(ignoredActions)
        return actions.count > 0
    }
    
    private func isRowWithoutHintableChildren() -> Bool {
        hintableChildrenCount() == 0 && root.role == "AXRow"
    }
    
    private func hintableChildrenCount() -> Int {
        if let hintableChildrenCount = cachedHintableChildrenCount {
            return hintableChildrenCount
        }
        let children = self.children ?? []
        let hintableChildrenCount = children
            .map { $0.hintableChildrenCount() }
            .reduce(0, +)
        self.cachedHintableChildrenCount = hintableChildrenCount
        return hintableChildrenCount
    }
}

class SafariWebAreaElementTreeNode : ElementTreeNode {
    override func isHintable() -> Bool {
        return true
    }
}

