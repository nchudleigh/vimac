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
        for app in apps {
            // set the messaging timeout to lower than the global timeout
            // we are sending mach messages to processes that are not ours.
            // there is a good chance several non responsive processes exist which could lead to a much slower hint query time.
            // since extra menu bar items are not as essential as elements on the active window,
            // we set a lower timeout.
            app.messagingTimeout = 0.05
        }
        
        let menubarsOptional: [UIElement?] = apps.map({ app in
            return try? app.attribute(.extrasMenuBar)
        })
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
