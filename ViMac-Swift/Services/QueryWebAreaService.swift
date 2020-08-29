//
//  QueryWebAreaService.swift
//  Vimac
//
//  Created by Dexter Leng on 28/8/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class QueryWebAreaService {
    let webAreaElement: UIElement

    init(webAreaElement: UIElement) {
        self.webAreaElement = webAreaElement
    }
    
    func perform() throws -> [UIElement]? {
        let query: [String: Any] = [
            "AXDirection": "AXDirectionNext",
            "AXImmediateDescendantsOnly": false,
            "AXResultsLimit": -1,
            "AXVisibleOnly": true,
            "AXSearchKey": "AXAnyTypeSearchKey"
        ]
        let rawElements: [AXUIElement]? = try webAreaElement.parameterizedAttribute("AXUIElementsForSearchPredicate", param: query)
        let elements = rawElements?.map({ UIElement($0) })
        return elements
    }
}
