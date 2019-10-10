//
//  ModeViewController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class ModeViewController: NSViewController, OverlayTextFieldDelegate {
    weak var modeCoordinator: ModeCoordinator?
    
    override func loadView() {
        self.view = NSView()
    }
    
    func onEscape() {
        self.modeCoordinator?.exitMode()
    }
}
