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
    var keySequenceTimer: Timer = Timer()
    var scrollModeInputState: ScrollModeInputState
    var borderView: BorderView?
    var scroller: Scroller?
    let disposeBag = DisposeBag()
    
    init(scrollArea: Element, inputListener: InputListener) {
        self.scrollArea = scrollArea
        self.inputListener = inputListener
        self.scrollModeInputState = ScrollModeInputState.instantiate()
        
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
        moveMouseToScrollAreaCenter()
        observeKeyDown().disposed(by: disposeBag)
        observeKeyUp().disposed(by: disposeBag)
    }
    
    private func setBorderView() {
        if let borderView = borderView {
            borderView.removeFromSuperview()
        }

        self.borderView = BorderView(frame: .init(origin: .zero, size: self.view.frame.size))
        self.view.addSubview(self.borderView!)
    }
    
    private func moveMouseToScrollAreaCenter() {
        let scrollAreaPosition = scrollArea.frame.origin
        let scrollAreaSize = scrollArea.frame.size
        
        let positionX = scrollAreaPosition.x + (scrollAreaSize.width / 2)
        let positionY = scrollAreaPosition.y + scrollAreaSize.height - (scrollAreaSize.height / 2)
        let position = NSPoint(x: positionX, y: positionY)
        Utils.moveMouse(position: position)
    }
    
    private func observeKeyDown() -> Disposable {
        return inputListener.keyDownEvents.bind(onNext: { [weak self] event in
            guard let self = self else { return }
            guard let characters = event.characters else { return }
            
            if self.isScrolling() {
                return
            }
            
            for c in characters {
                let status = try! self.scrollModeInputState.advance(key: c)
                switch status {
                case .advancable:
                    self.setKeySequenceTimeout()
                    break
                case .deadend:
                    self.resetInputState()
                case .match(let scrollDirection):
                    self.scroll(scrollDirection)
                    self.resetInputState()
                    break
                }
            }
        })
    }
    
    @objc private func onTimeout() {
        self.resetInputState()
    }
    
    private func setKeySequenceTimeout() {
        let resetDelay = 0.25
        self.keySequenceTimer.invalidate()
        self.keySequenceTimer = Timer.scheduledTimer(timeInterval: resetDelay, target: self, selector: #selector(onTimeout), userInfo: nil, repeats: false)
    }
    
    private func observeKeyUp() -> Disposable {
        return inputListener.keyUpEvents.bind(onNext: { [weak self] event in
            guard let self = self else { return }
            
            self.stopScrolling()
        })
    }
    
    private func scroll(_ direction: ScrollDirection) {
        if [.left, .right, .up, .down, .top, .bottom].contains(direction) {
            self.scroller = ChunkyScroller.instantiateForSmoothScroll(direction: direction)
            self.scroller?.start()
            return
        }
        
        if [.halfLeft, .halfRight, .halfUp, .halfDown].contains(direction) {
            if [.halfLeft, .halfRight].contains(direction) {
                self.scroller = ChunkyScroller.instantiate(direction: direction, scrollAmount: Int(scrollArea.frame.width / 2))
            } else {
                self.scroller = ChunkyScroller.instantiate(direction: direction, scrollAmount: Int(scrollArea.frame.height / 2))
            }
            self.scroller?.start()
            return
        }
    }
    
    private func resetInputState() {
        scrollModeInputState = ScrollModeInputState.instantiate()
    }
    
    private func isScrolling() -> Bool {
        scroller != nil
    }
    
    private func stopScrolling() {
        scroller?.stop()
        scroller = nil
    }
}
