//
//  FlattenElementTreeNode.swift
//  Vimac
//
//  Created by Dexter Leng on 23/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

class FlattenElementTreeNode {
    let root: ElementTreeNode
    var result: [Element] = []

    init(_ root: ElementTreeNode) {
        self.root = root
    }
    
    func perform() -> [Element] {
        assert(root.root.role == "AXWindow")
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
