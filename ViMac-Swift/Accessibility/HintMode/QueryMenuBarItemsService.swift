//
//  QueryMenuBarItemsService.swift
//  Vimac
//
//  Created by Dexter Leng on 7/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class QueryMenuBarItemsService {
    let applicationElement: AXUIElement

    init(applicationElement: AXUIElement) {
        self.applicationElement = applicationElement
    }
    
    func perform() throws -> [Element]? {
        let appUIElement = UIElement(applicationElement)
        
        let menuBarOptional: UIElement? = try appUIElement.attribute(.menuBar)
        guard let menuBar = menuBarOptional else { return nil }
        
        let menuBarItemsOptional: [AXUIElement]? = try? menuBar.attribute(.children)
        guard let menuBarItems = menuBarItemsOptional else { return nil }
        
        return menuBarItems
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
    }
}
