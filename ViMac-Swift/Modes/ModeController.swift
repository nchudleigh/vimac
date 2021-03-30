//
//  ModeController.swift
//  Vimac
//
//  Created by Dexter Leng on 21/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

protocol ModeController {
    var delegate: ModeControllerDelegate? { get set }

    func activate()
    func deactivate()
}

protocol ModeControllerDelegate: AnyObject {
    func modeDeactivated(controller: ModeController)
}
