//
//  HintModeWindowQuery.swift
//  Vimac
//
//  Created by Dexter Leng on 21/7/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class HintModeWindowQuery : ElementQuery {
    func onElement(element: Element, context: [String : Any]) -> ElementQueryAction {
        element.bulkCacheAttributes()
        
        if !areElementAttributesPresent(element: element, attributes: [.role, .position, .size]) {
            return ElementQueryAction.init(includeElement: false, visitChildren: false, childrenContext: nil)
        }
        
        if !shouldIncludeElement(element: element, context: context) {
            return ElementQueryAction.init(includeElement: false, visitChildren: false, childrenContext: nil)
        }
        
        return ElementQueryAction.init(
            includeElement: true,
            visitChildren: true,
            childrenContext: childrenContext(element: element, context: context)
        )
    }
    
    private func areElementAttributesPresent(element: Element, attributes: [Attribute]) -> Bool {
        for attribute in attributes {
            let v: Any? = element.attribute(attr: attribute)
            if v == nil {
                return false
            }
        }
        return true
    }

    private func shouldIncludeElement(element: Element, context: [String : Any]) -> Bool {
        guard let elementFrame = element.frame(),
            let _ = element.role(),
            let _ = element.position() else {
            return false
        }

        guard let parentContainerFrame = context["parent_container_frame"] as? NSRect else {
            return true
        }
        
        let withinParentContainerFrame = parentContainerFrame.intersects(elementFrame)
        if !withinParentContainerFrame {
            return false
        }
        
        return true
    }
    
    private func childrenContext(element: Element, context: [String : Any]) -> [String : Any] {
        let role = element.role()!
        let frame = element.frame()!
        
        // dicts are values. this creates a copy
        var childrenContext = context
        
        let containerRoles = [
            Role.scrollArea.rawValue,
            Role.row.rawValue,
            "AXPage",
            Role.group.rawValue
        ]
        
        if containerRoles.contains(role) {
            childrenContext["parent_container_frame"] = frame
        }

        return childrenContext
    }
}
