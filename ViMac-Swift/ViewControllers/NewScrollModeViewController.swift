//
//  NewScrollModeViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 14/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class NewScrollModeViewController: ModeViewController {
    override func viewWillAppear() {
        setLoadingState()
    }
    
    private func setLoadingState() {
        let vc = ScrollModeLoadingViewController()
        setChildViewController(vc)
    }
    
    private func setChildViewController(_ vc: NSViewController) {
        assert(self.children.count <= 1)
        removeChildViewController()
        
        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
    }
    
    private func removeChildViewController() {
        guard let childVC = self.children.first else { return }
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}
