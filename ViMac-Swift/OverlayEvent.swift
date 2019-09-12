//
//  OverlayEvent.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 12/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import AXSwift

enum OverlayEvent {
    case activeWindowUpdated, newActiveWindow(window: UIElement), noActiveWindow
}
