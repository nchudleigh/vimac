//
//  ModeViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
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
