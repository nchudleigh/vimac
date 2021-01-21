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
    let app: NSRunningApplication

    init(app: NSRunningApplication) {
        self.app = app
    }
    
    func perform() throws -> [Element]? {
        guard let appUIElement = Application(app) else { return nil }
        
        let menuBarOptional: UIElement? = try appUIElement.attribute(.menuBar)
        guard let menuBar = menuBarOptional else { return nil }
        
        let menuBarItemsOptional: [AXUIElement]? = try? menuBar.attribute(.children)
        guard let menuBarItems = menuBarItemsOptional else { return nil }
        
        return menuBarItems
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
    }
}
