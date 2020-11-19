//
//  ScrollModeActiveViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 15/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class ScrollModeActiveViewController: NSViewController {
    let scrollAreas: [Element]
    var activeScrollAreaIndex: Int = 0
    let inputListener: InputListener
    
    init(scrollAreas: [Element], inputListener: InputListener) {
        assert(scrollAreas.count > 0)

        self.scrollAreas = scrollAreas
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
        setActiveScrollArea(0)
    }
    
    private func setActiveScrollArea(_ index: Int) {
        let scrollArea = scrollAreas[index]
        self.activeScrollAreaIndex = index
        
        setActiveScrollAreaVC(scrollArea)
    }
    
    private func setActiveScrollAreaVC(_ scrollArea: Element) {
        let frame: NSRect = {
            let topLeftPositionRelativeToScreen = Utils.toOrigin(point: scrollArea.frame.origin, size: scrollArea.frame.size)
            let topLeftPositionRelativeToWindow = self.view.window!.convertPoint(fromScreen: topLeftPositionRelativeToScreen)
            return NSRect(origin: topLeftPositionRelativeToWindow, size: scrollArea.frame.size)
        }()
        let vc = ScrollModeActiveScrollAreaViewController(scrollArea: scrollArea, inputListener: inputListener)
        vc.view.frame = frame
        setChildViewController(vc)
    }
    
    private func setChildViewController(_ vc: NSViewController) {
        assert(self.children.count <= 1)
        removeChildViewController()
        
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    private func removeChildViewController() {
        guard let childVC = self.children.first else { return }
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}
