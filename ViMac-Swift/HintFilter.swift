//
//  HintFilter.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 19/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

protocol ElementFilter {
    static func filterPredicate(element: UIElement) -> Bool
}

class NoFilter : ElementFilter {
    static func filterPredicate(element: UIElement) -> Bool {
        return true
    }
}

class HasActionsFilter : ElementFilter {
    static func filterPredicate(element: UIElement) -> Bool {
        do {
            return try element.actions().count > 0
        } catch {
            return false
        }
    }
}
