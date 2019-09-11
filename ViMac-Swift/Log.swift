//
//  Log.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 11/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import os

private let subsystem = "com.dexterleng.vimac"

struct Log {
    static let accessibility = OSLog(subsystem: subsystem, category: "accessiblity")
    static let drawing = OSLog(subsystem: subsystem, category: "drawing")
}
