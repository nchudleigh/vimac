//
//  QueryMenuBarExtrasService.swift
//  Vimac
//
//  Created by Dexter Leng on 7/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class QueryMenuBarExtrasService {
    func perform() throws -> [Element]? {
        let apps = Application.all()
        let menubarsOptional: [UIElement?] = apps.map({ try? $0.attribute(.extrasMenuBar) })
        let menubars = menubarsOptional.compactMap({ $0 })
        let menubarItemsUnflattened: [[AXUIElement]] = menubars.map({ menubar in
            let items: [AXUIElement]? = try? menubar.attribute(.children)
            return items ?? []
        })
        let menubarItems = Array(menubarItemsUnflattened.joined())
        
        return menubarItems
            .map({ Element.initialize(rawElement: $0) })
            .compactMap({ $0 })
    }
}
