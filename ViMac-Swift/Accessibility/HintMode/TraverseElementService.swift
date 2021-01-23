//
//  TraverseElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 6/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

protocol TraverseElementService {
    init(element: Element, app: NSRunningApplication, windowElement: Element, containerElement: Element?)
    func perform() -> ElementTreeNode?
}
