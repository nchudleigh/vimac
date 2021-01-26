//
//  TraverseElementServiceFinder.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class TraverseElementServiceFinder {
    let app: NSRunningApplication
    let element: Element
    
    init(app: NSRunningApplication, element: Element) {
        self.app = app
        self.element = element
    }
    
    func find() -> TraverseElementService.Type {
        if element.role == "AXWebArea" && supportsChildrenThroughSearchPredicate() {            
            return TraverseSearchPredicateCompatibleWebAreaElementService.self
        }
        
        return TraverseGenericElementService.self
    }
    
    private func supportsChildrenThroughSearchPredicate() -> Bool {
        let parameterizedAttrs = try? UIElement(element.rawElement).parameterizedAttributesAsStrings()
        return parameterizedAttrs?.contains("AXUIElementsForSearchPredicate") ?? false
    }
}

