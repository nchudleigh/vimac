//
//  ScrollModeLoadingViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 15/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class ScrollModeLoadingViewController: NSViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = .black
        self.view.layer?.opacity = 0.3
    }
}
