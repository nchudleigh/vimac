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
    let app: NSRunningApplication
    let window: Element
    
    init(app: NSRunningApplication, window: Element) {
        self.app = app
        self.window = window
    }
    
    func perform() -> [Element] {
        let tree = ElementTree()
        TraverseElementServiceFinder
            .init(app: app, element: window).find()
            .init(tree: tree, element: window, parent: nil, app: app, windowElement: window, clipBounds: nil).perform()
        
        let elements = tree.query() ?? []
        return elements
    }
}
