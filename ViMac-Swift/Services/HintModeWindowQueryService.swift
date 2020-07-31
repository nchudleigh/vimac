//
//  HintModeWindowQueryService.swift
//  Vimac
//
//  Created by Dexter Leng on 21/7/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class HintModeWindowQueryService {
    let windowElement: Element
    let queryElementService: QueryElementService
    
    init(windowElement: Element) {
        self.windowElement = windowElement
        self.queryElementService = QueryElementService(rootElement: windowElement, query: HintModeWindowQuery())
    }
    
    func query(onComplete: @escaping ([Element]) -> ()) {
        try! queryElementService.perform(onComplete: { [weak self] store in
            let elements = try! store.flatten(element: self!.windowElement)
            onComplete(elements)
        })
    }
}
