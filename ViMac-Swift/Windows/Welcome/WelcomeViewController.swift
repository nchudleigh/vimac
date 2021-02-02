//
//  WelcomeViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 11/1/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class WelcomeViewController: NSViewController {

    @IBAction func onGrantPermissionButtonClick(_ sender: Any) {
        _ = UIElement.isProcessTrusted(withPrompt: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
