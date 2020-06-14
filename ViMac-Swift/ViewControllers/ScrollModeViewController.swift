//
//  ScrollModeViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import Carbon.HIToolbox
import AXSwift

class ScrollModeViewController: ModeViewController {
    let inputListener: ScrollModeInputListener = ScrollModeInputListenerFactory.instantiate()
    let borderView: BorderView = ScrollModeViewController.instantiateBorderView()
    let inputListeningTextField: NSTextField = ScrollModeViewController.instantiateInputListeningTextField()
    let scrollAreas = getScrollAreasByDescendingArea()
    let activeScrollAreaIndex = BehaviorSubject<Int>(value: 0)
    let originalMousePosition = NSEvent.mouseLocation
    var scroller: Scroller?
    
    let disposeBag = DisposeBag()
    
    static func getScrollAreasByDescendingArea() -> [(NSSize, NSPoint)] {
        let scrollAreas = getScrollAreaElementsByDescendingArea()
        var sizePositionTuple = scrollAreas.map({ area -> (NSSize, NSPoint) in
            let size: NSSize? = try? area.attribute(.size)
            let position: NSPoint? = try? area.attribute(.position)
            return (size!, position!)
        })
        if sizePositionTuple.count == 0 {
            if let applicationWindow = Utils.getCurrentApplicationWindowManually() {
                let appSize: NSSize? = try? applicationWindow.attribute(.size)
                let appPosition: NSPoint? = try? applicationWindow.attribute(.position)
                sizePositionTuple.append((appSize!, appPosition!))
            }
        }
        return sizePositionTuple
    }
    
    static func getScrollAreaElementsByDescendingArea() -> [CachedUIElement] {
        guard let applicationWindow = Utils.getCurrentApplicationWindowManually() else {
            return []
        }
        
        let cachedApplicationWindow = CachedUIElement.init(applicationWindow.element)
        
        var scrollAreas = [CachedUIElement]()
        func populateScrollAreas(element: CachedUIElement) -> Void {
            _ = try? element.getMultipleAttributes([.role, .position, .size, .children])

            let roleOptional: String? = try? element.attribute(.role);
            
            if let role = roleOptional {
                if role == Role.scrollArea.rawValue {
                    scrollAreas.append(element)
                    return
                }
            }

            let children = (try? element.attribute(Attribute.children) as [AXUIElement]?) ?? [];

            for child in children {
                populateScrollAreas(element: CachedUIElement(child))
            }
        }
        populateScrollAreas(element: cachedApplicationWindow)
        
        let scrollAreasDescendingArea = scrollAreas.sorted(by: { (scrollAreaA, scrollAreaB) in
            let sizeA: NSSize = (try? scrollAreaA.attribute(.size)) ?? .zero;
            let sizeB: NSSize = (try? scrollAreaB.attribute(.size)) ?? .zero;
            return (sizeA.width * sizeA.height) > (sizeB.width * sizeB.height)
        })
        
        return scrollAreasDescendingArea
    }
    
    deinit {
        print("scroll mode view controller deinitialized")
        
        self.scroller?.stop()
    }
    
    override func viewDidLoad() {
        self.view.addSubview(inputListeningTextField)
        inputListeningTextField.becomeFirstResponder()
        
        self.view.addSubview(borderView)
        
        hideMouse()
        
        disposeBag.insert(observeScrollEvents())
        disposeBag.insert(observeEscapeEvents())
        disposeBag.insert(observeTabEvents())
        disposeBag.insert(observeActiveScrollAreaChange())
    }
    
    override func viewDidDisappear() {
        revertMouseLocation()
        showMouse()
    }
    
    
    func on(scrollEvent: ScrollModeInputListener.ScrollEvent) {
        print(scrollEvent)
        
        self.scroller?.stop()
        
        if scrollEvent.state == .start && [.left, .right, .up, .down].contains(scrollEvent.direction) {
            self.scroller = SmoothScroller.instantiate(direction: scrollEvent.direction)
            self.scroller?.start()
        }
        
        if scrollEvent.state == .start && [.halfLeft, .halfRight, .halfUp, .halfDown].contains(scrollEvent.direction) {
            if let activeScrollArea = self.activeScrollArea() {
                if [.halfLeft, .halfRight].contains(scrollEvent.direction) {
                    self.scroller = ChunkyScroller.instantiate(direction: scrollEvent.direction, scrollAmount: Int(activeScrollArea.0.width / 2))
                } else {
                    self.scroller = ChunkyScroller.instantiate(direction: scrollEvent.direction, scrollAmount: Int(activeScrollArea.0.height / 2))
                }
                self.scroller?.start()
            }
        }
    }
    
    func activeScrollArea() -> (NSSize, NSPoint)? {
        let index = try! activeScrollAreaIndex.value()
        
        if scrollAreas.count == 0 {
            return nil
        }
        
        return scrollAreas[index]
    }
    
    func activateScrollArea(scrollArea: (NSSize, NSPoint)) {
        resizeBorderViewToFitScrollArea(scrollAreaSize: scrollArea.0, scrollAreaPosition: scrollArea.1)
        moveMouseToScrollAreaCenter(scrollAreaPosition: scrollArea.1, scrollAreaSize: scrollArea.0)
    }
    
    func resizeBorderViewToFitScrollArea(scrollAreaSize: NSSize, scrollAreaPosition: NSPoint) {
        let topLeftPositionRelativeToScreen = Utils.toOrigin(point: scrollAreaPosition, size: scrollAreaSize)
        guard let topLeftPositionRelativeToWindow = self.modeCoordinator?.windowController.window?.convertPoint(fromScreen: topLeftPositionRelativeToScreen) else {
            return
        }
        self.borderView.frame = NSRect(origin: topLeftPositionRelativeToWindow, size: scrollAreaSize)
    }
    
    func moveMouseToScrollAreaCenter(scrollAreaPosition: NSPoint, scrollAreaSize: NSSize) {
        let positionX = scrollAreaPosition.x + (scrollAreaSize.width / 2)
        let positionY = scrollAreaPosition.y + scrollAreaSize.height - (scrollAreaSize.height / 2)
        let position = NSPoint(x: positionX, y: positionY)
        Utils.moveMouse(position: position)
    }
    
    func activateNextScrollArea() {
        let currentIndex = try! activeScrollAreaIndex.value()
        let nextIndex = (currentIndex + 1) % scrollAreas.count
        activeScrollAreaIndex.onNext(nextIndex)
    }
    
    func revertMouseLocation() {
        Utils.moveMouse(position: Utils.toOrigin(point: originalMousePosition, size: NSSize.zero))
    }
    
    func hideMouse() {
        HideCursorGlobally.hide()
    }
    
    func showMouse() {
        HideCursorGlobally.unhide()
    }
    
    func observeActiveScrollAreaChange() -> Disposable {
        return activeScrollAreaIndex.bind(onNext: { [weak self] i in
            if self!.scrollAreas.count == 0 {
                return
            }
            
            let scrollArea = self!.scrollAreas[i]
            self!.activateScrollArea(scrollArea: scrollArea)
        })
    }
    
    func observeScrollEvents() -> Disposable {
        inputListener.scrollEventSubject.bind(onNext: { [weak self] event in
            self?.on(scrollEvent: event)
        })
    }
    
    func observeEscapeEvents() -> Disposable {
        return inputListener.escapeEventSubject.bind(onNext: { [weak self] _ in
            self?.onEscape()
        })
    }
    
    func observeTabEvents() -> Disposable {
        return inputListener.tabEventSubject.bind(onNext: { [weak self] _ in
            self?.activateNextScrollArea()
        })
    }

    static func instantiateInputListeningTextField() -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = ""
        textField.isEditable = true
        return textField
    }
    
    static func instantiateBorderView() -> BorderView {
        return BorderView()
    }
}
