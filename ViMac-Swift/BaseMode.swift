//
//  BaseMode.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 18/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

protocol BaseModeProtocol {
    func deactivate() -> Void
    func activate() -> Void
//    init(applicationWindow: UIElement)
}

protocol ModeDelegate: AnyObject {
    func onDeactivate() -> Void
}
