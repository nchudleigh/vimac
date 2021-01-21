//
//  Element.swift
//  Vimac
//
//  Created by Dexter Leng on 5/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

struct Element {
    let rawElement: AXUIElement
    let frame: NSRect
    let actions: [String]
    let role: String
    
    static func initialize(rawElement: AXUIElement) -> Element? {
        let uiElement = UIElement.init(rawElement)
        let valuesOptional = try? uiElement.getMultipleAttributes([.size, .position, .role])
        
        guard let values = valuesOptional else {
            return nil
        }

        guard let size: NSSize = values[Attribute.size] as! NSSize? else { return nil }
        guard let position: NSPoint = values[Attribute.position] as! NSPoint? else { return nil }
        guard let role: String = values[Attribute.role] as! String? else { return nil }
        let frame = NSRect(origin: position, size: size)

        guard let actions = try? uiElement.actionsAsStrings() else { return nil }
        
        return Element.init(rawElement: rawElement, frame: frame, actions: actions, role: role)
    }
}

class ElementTreeNode {
    let root: Element
    let children: [ElementTreeNode]?
    private var cachedHintableChildrenCount: Int?
    
    init(root: Element, children: [ElementTreeNode]?) {
        self.root = root
        self.children = children
    }
    
    func isHintable() -> Bool {
        isActionable() || isRowWithoutHintableChildren()
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
