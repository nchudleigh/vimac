//
//  Command.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 20/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

enum CursorAction: String {
    case leftClick = "c"
    case rightClick = "rc"
    case doubleLeftClick = "dc"
    case move = "m"
}

enum CursorSelector: String {
    case element = "e"
    case here = "h"
}

enum ElementSelectorArg: String {
    case button = "b"
    case disclosureTriangle = "dt"
    case group = "grp"
    case row = "r"
    case image = "i"
    case text = "t"
    case link = "l"
}
