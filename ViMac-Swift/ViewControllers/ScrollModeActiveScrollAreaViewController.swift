//
//  ScrollModeActiveScrollAreaViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 15/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class ScrollModeActiveScrollAreaViewController: NSViewController {
    let scrollArea: Element
    let inputListener: InputListener
    var borderView: BorderView?
    
    init(scrollArea: Element, inputListener: InputListener) {
        self.scrollArea = scrollArea
        self.inputListener = inputListener
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidAppear() {
        setBorderView()
    }
    
    private func setBorderView() {
        if let borderView = borderView {
            borderView.removeFromSuperview()
        }

        self.borderView = BorderView(frame: .init(origin: .zero, size: self.view.frame.size))
        self.view.addSubview(self.borderView!)
    }
}
