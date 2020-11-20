//
//  QueryScrollAreasService.swift
//  Vimac
//
//  Created by Dexter Leng on 14/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import AXSwift

class QueryScrollAreasService {
    let windowElement: Element
    
    init(windowElement: Element) {
        self.windowElement = windowElement
    }
    
    func perform() throws -> [Element] {
        let scrollAreas = try fetchScrollAreas()
        let scrollAreasDescendingArea = scrollAreas.sorted(by: { (a, b) in
            (a.frame.width * a.frame.height) > (b.frame.width * b.frame.height)
        })
        return scrollAreasDescendingArea
    }
    
    private func fetchScrollAreas() throws -> [Element] {
        var scrollAreas = [Element]()
        var stack: [Element] = [windowElement]
        
        while stack.count > 0 {
            let element = stack.popLast()!
            
            if element.role == "AXScrollArea" {
                scrollAreas.append(element)
                continue
            }
            
            let children = try fetchChildren(element) ?? []
            for child in children {
                stack.append(child)
            }
        }
        
        return scrollAreas
    }
    
    private func fetchChildren(_ element: Element) throws -> [Element]? {
        let rawElementsOptional: [AXUIElement]? = try {
            if element.role == "AXTable" || element.role == "AXOutline" {
                return try UIElement(element.rawElement).attribute(.visibleRows)
            }
            return try UIElement(element.rawElement).attribute(.children)
        }()
        
        guard let rawElements = rawElementsOptional else {
            return nil
        }
        
        return rawElements
            .map { Element.initialize(rawElement: $0) }
            .compactMap({ $0 })
    }
}
