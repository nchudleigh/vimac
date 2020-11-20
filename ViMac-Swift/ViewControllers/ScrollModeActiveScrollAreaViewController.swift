//
//  ScrollModeActiveScrollAreaViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 15/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class ScrollModeActiveScrollAreaViewController: NSViewController {
    let scrollArea: Element
    let inputListener: InputListener
    let scrollModeInputListener: ScrollModeInputListener
    var borderView: BorderView?
    var scroller: Scroller?
    let disposeBag = DisposeBag()
    
    init(scrollArea: Element, inputListener: InputListener) {
        self.scrollArea = scrollArea
        self.inputListener = inputListener
        self.scrollModeInputListener = ScrollModeInputListener(
            scrollKeyConfig: UserPreferences.ScrollMode.ScrollKeysProperty.readAsConfig(),
            inputListener: self.inputListener
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        self.scroller?.stop()
    }
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidAppear() {
        setBorderView()
        observeScrollEvents().disposed(by: disposeBag)
        moveMouseToScrollAreaCenter()
    }
    
    private func setBorderView() {
        if let borderView = borderView {
            borderView.removeFromSuperview()
        }

        self.borderView = BorderView(frame: .init(origin: .zero, size: self.view.frame.size))
        self.view.addSubview(self.borderView!)
    }
    
    private func observeScrollEvents() -> Disposable {
        scrollModeInputListener.scrollEventSubject.bind(onNext: { [weak self] event in
            self?.on(scrollEvent: event)
        })
    }
    
    private func on(scrollEvent: ScrollModeInputListener.ScrollEvent) {
        self.scroller?.stop()
        
        if scrollEvent.state == .start && [.left, .right, .up, .down].contains(scrollEvent.direction) {
            self.scroller = SmoothScroller.instantiate(direction: scrollEvent.direction)
            self.scroller?.start()
        }
        
        if scrollEvent.state == .start && [.halfLeft, .halfRight, .halfUp, .halfDown].contains(scrollEvent.direction) {
            if [.halfLeft, .halfRight].contains(scrollEvent.direction) {
                self.scroller = ChunkyScroller.instantiate(direction: scrollEvent.direction, scrollAmount: Int(scrollArea.frame.width / 2))
            } else {
                self.scroller = ChunkyScroller.instantiate(direction: scrollEvent.direction, scrollAmount: Int(scrollArea.frame.height / 2))
            }
            self.scroller?.start()
        }
    }
    
    private func moveMouseToScrollAreaCenter() {
        let scrollAreaPosition = scrollArea.frame.origin
        let scrollAreaSize = scrollArea.frame.size
        
        let positionX = scrollAreaPosition.x + (scrollAreaSize.width / 2)
        let positionY = scrollAreaPosition.y + scrollAreaSize.height - (scrollAreaSize.height / 2)
        let position = NSPoint(x: positionX, y: positionY)
        Utils.moveMouse(position: position)
    }
}
