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
    let windowElement: UIElement
    
    init(windowElement: UIElement) {
        self.windowElement = windowElement
    }
    
    func perform() throws -> [UIElement] {
        let windowFrameOptional: NSRect? = try? self.windowElement.attribute(.frame)
        let windowFrame = windowFrameOptional!
        
        var elements: [UIElement] = []
        var stack: [(UIElement, NSRect?)] = [(self.windowElement, nil)]
        
        while stack.count > 0 {
            let (head, parentContainerFrameOptional) = stack.popLast()!
            let valuesOptional = try? head.getMultipleAttributes([.size, .position, .role])
            
            guard let values = valuesOptional else { continue }

            guard let size: NSSize = values[Attribute.size] as! NSSize? else { continue }
            guard let position: NSPoint = values[Attribute.position] as! NSPoint? else { continue }
            guard let role: String = values[Attribute.role] as! String? else { continue }
            let frame = NSRect(origin: position, size: size)

            if !frame.intersects(windowFrame) {
                continue
            }

            if let parentContainerFrame = parentContainerFrameOptional {
                if !frame.intersects(parentContainerFrame) {
                    continue
                }
            }
            
            let childrenParentContainerFrame: NSRect? = {
                let containerRoles = [
                    Role.scrollArea.rawValue,
                    Role.row.rawValue,
                    "AXPage"
                ]

                if containerRoles.contains(role) || role.lowercased().contains("group") {
                    return frame
                }

                return parentContainerFrameOptional
            }()

            // this function should be executed in a thread
            // the actions are cached here so that when we ask for actions again in main thread it doesn't block
            try? head.actionsAsStrings()
            
            if role == "AXWebArea" {
                if let parameterizedAttrs = try? head.parameterizedAttributesAsStrings() {
                    if parameterizedAttrs.contains("AXUIElementsForSearchPredicate") {
                        let service = QueryWebAreaService.init(webAreaElement: head)
                        let webAreaElements = try? service.perform()
                        elements.append(contentsOf: webAreaElements ?? [])
                        continue
                    }
                }
            }

            elements.append(head)
            
            let childrenOptional: [AXUIElement]? = {
                if role == "AXTable" || role == "AXOutline" {
                    return try? head.attribute(.visibleRows)
                } else {
                    return try? head.attribute(.children)
                }
            }()
            
            let children = childrenOptional ?? []
            
            let childrenElement: [CachedUIElement] = children.map { CachedUIElement($0) }
            for child in childrenElement {
                stack.append((child, childrenParentContainerFrame))
            }
        }
        return elements
    }
}
