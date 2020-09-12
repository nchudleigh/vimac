//
//  TraverseElementServiceFinder.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class TraverseElementServiceFinder {
    let element: Element
    
    init(_ element: Element) {
        self.element = element
    }
    
    func find() -> TraverseElementService.Type {
        if element.role == "AXWebArea" {
            return TraverseWebAreaElementService.self
        }
        
        return TraverseGenericElementService.self
    }
}

