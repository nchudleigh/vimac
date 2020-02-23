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

class ScrollModeViewController: ModeViewController, NSTextFieldDelegate {
    let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    let borderView = BorderView();
    var scrollKeysDisposable: Disposable?
    var compositeDisposable: CompositeDisposable = CompositeDisposable()
    var currentScrollAreaIndex = 0
    let scrollAreas = getScrollAreasByDescendingArea()
    var originalMousePosition: NSPoint?

    static func getScrollAreasByDescendingArea() -> [CachedUIElement] {
        guard let applicationWindow = Utils.getCurrentApplicationWindowManually() else {
            return []
        }
        
        let cachedApplicationWindow = CachedUIElement.init(applicationWindow.element)
        
        var scrollAreas = [CachedUIElement]()
        func fn(element: CachedUIElement) -> Void {
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
                fn(element: CachedUIElement(child))
            }
        }
        fn(element: cachedApplicationWindow)
        let scrollAreasDescendingArea = scrollAreas.sorted(by: { (scrollAreaA, scrollAreaB) in
            let sizeA: NSSize = (try? scrollAreaA.attribute(.size)) ?? .zero;
            let sizeB: NSSize = (try? scrollAreaB.attribute(.size)) ?? .zero;
            return (sizeA.width * sizeA.height) > (sizeB.width * sizeB.height)
        })
        return scrollAreasDescendingArea
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        textField.overlayTextFieldDelegate = self
        self.view.addSubview(textField)
        self.view.addSubview(borderView)
        
        self.originalMousePosition = NSEvent.mouseLocation
        HideCursorGlobally.hide()

        self.scrollKeysDisposable = self.setActiveScrollArea(index: self.currentScrollAreaIndex)
        
        let tabKeyDownObservable = textField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Tab && event.type == .keyDown
        })
        
        let escapeKeyDownObservable = textField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Escape && event.type == .keyDown
        })
        
        self.compositeDisposable.insert(tabKeyDownObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.scrollKeysDisposable?.dispose()
                self?.scrollKeysDisposable = self?.cycleActiveScrollArea()
            })
        )
        
        self.compositeDisposable.insert(escapeKeyDownObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.onEscape()
            })
        )
    }
    
    func cycleActiveScrollArea() -> Disposable? {
        self.currentScrollAreaIndex = (self.currentScrollAreaIndex + 1) % self.scrollAreas.count
        return self.setActiveScrollArea(index: self.currentScrollAreaIndex)
    }
    
    func setActiveScrollArea(index: Int) -> Disposable? {
        if index < 0 || index >= scrollAreas.count {
            return nil
        }
        let scrollArea = scrollAreas[index]
        let scrollAreaSizeOptional: NSSize? = try? scrollArea.attribute(.size)
        let scrollAreaPositionOptional: NSPoint? = try? scrollArea.attribute(.position)
        guard let scrollAreaSize = scrollAreaSizeOptional,
            let scrollAreaPosition = scrollAreaPositionOptional else {
            self.modeCoordinator?.exitMode()
            return nil
        }

        resizeBorderViewToFitScrollArea(scrollAreaSize: scrollAreaSize, scrollAreaPosition: scrollAreaPosition)
        moveMouseToScrollAreaCenter(scrollAreaPosition: scrollAreaPosition, scrollAreaSize: scrollAreaSize)
        return setupScrollObservers(scrollAreaSize: scrollAreaSize, scrollAreaPosition: scrollAreaPosition)
    }
    
    func resizeBorderViewToFitScrollArea(scrollAreaSize: NSSize, scrollAreaPosition: NSPoint) {
        let topLeftPositionRelativeToScreen = Utils.toOrigin(point: scrollAreaPosition, size: scrollAreaSize)
        guard let topLeftPositionRelativeToWindow = self.modeCoordinator?.windowController.window?.convertPoint(fromScreen: topLeftPositionRelativeToScreen) else {
            return
        }
        self.borderView.frame = NSRect(origin: topLeftPositionRelativeToWindow, size: scrollAreaSize)
    }
    
    func setupScrollObservers(scrollAreaSize: NSSize, scrollAreaPosition: NSPoint) -> Disposable {
        let scrollSensitivity = UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey)
        let isVerticalScrollReversed = UserDefaults.standard.bool(forKey: Utils.isVerticalScrollReversedKey)
        let isHorizontalScrollReversed = UserDefaults.standard.bool(forKey: Utils.isHorizontalScrollReversedKey)
        let verticalScrollMultiplier = isVerticalScrollReversed ? -1 : 1
        let horizontalScrollMultiplier = isHorizontalScrollReversed ? -1 : 1
        
        let jKeyObservable = ScrollModeViewController.scrollObservableSmooth(
                textField: textField,
                character: "j",
                yAxis: Int64(-1 * verticalScrollMultiplier * scrollSensitivity),
                xAxis: 0,
                frequencyMilliseconds: 20)
        
        let kKeyObservable = ScrollModeViewController.scrollObservableSmooth(
                textField: textField,
                character: "k",
                yAxis: Int64(verticalScrollMultiplier * scrollSensitivity),
                xAxis: 0,
                frequencyMilliseconds: 20)
        
        let hKeyObservable = ScrollModeViewController.scrollObservableSmooth(
                textField: textField,
                character: "h",
                yAxis: 0,
                xAxis: Int64(horizontalScrollMultiplier * scrollSensitivity),
                frequencyMilliseconds: 20)
        
        let lKeyObservable = ScrollModeViewController.scrollObservableSmooth(
                textField: textField,
                character: "l",
                yAxis: 0,
                xAxis: Int64(-1 * horizontalScrollMultiplier * scrollSensitivity),
                frequencyMilliseconds: 20)
        
        let halfScrollAreaHeight = Int(scrollAreaSize.height / 2)
        let halfScrollAreaWidth = Int(scrollAreaSize.width / 2)
        
        let dKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "d",
                yAxis: verticalScrollMultiplier * -1 * halfScrollAreaHeight,
                xAxis: 0, frequencyMilliseconds: 200)
        
        let uKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "u",
                yAxis: verticalScrollMultiplier * halfScrollAreaHeight,
                xAxis: 0,
                frequencyMilliseconds: 200)
        
        let shiftHKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "H",
                yAxis: 0,
                xAxis: horizontalScrollMultiplier * halfScrollAreaWidth,
                frequencyMilliseconds: 200)
        
        let shiftLKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "L",
                yAxis: 0,
                xAxis: -1 * horizontalScrollMultiplier * halfScrollAreaWidth,
                frequencyMilliseconds: 200)
        
        let shiftJKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "J",
                yAxis: -1 * verticalScrollMultiplier * halfScrollAreaHeight,
                xAxis: 0,
                frequencyMilliseconds: 200)
        
        let shiftKKeyObservable = ScrollModeViewController.scrollObservableChunky(
                textField: textField,
                character: "K",
                yAxis: verticalScrollMultiplier * halfScrollAreaHeight,
                xAxis: 0,
                frequencyMilliseconds: 200)
        
        let allScrollObservables = Observable.of(
            jKeyObservable,
            hKeyObservable,
            kKeyObservable,
            lKeyObservable,
            dKeyObservable,
            uKeyObservable,
            shiftHKeyObservable,
            shiftLKeyObservable,
            shiftJKeyObservable,
            shiftKKeyObservable
        ).merge()
        .do(onNext: { [weak self] in
            self?.moveMouseToScrollAreaCenter(scrollAreaPosition: scrollAreaPosition, scrollAreaSize: scrollAreaSize)
        })
        
        return allScrollObservables.subscribe()
    }
    
    func moveMouseToScrollAreaCenter(scrollAreaPosition: NSPoint, scrollAreaSize: NSSize) {
        let positionX = scrollAreaPosition.x + (scrollAreaSize.width / 2)
        let positionY = scrollAreaPosition.y + scrollAreaSize.height - (scrollAreaSize.height / 2)
        let position = NSPoint(x: positionX, y: positionY)
        Utils.moveMouse(position: position)
    }
    
    override func viewDidDisappear() {
        if let pos = self.originalMousePosition {
            Utils.moveMouse(position: Utils.toOrigin(point: pos, size: NSSize.zero))
        }
        HideCursorGlobally.unhide()
        self.compositeDisposable.dispose()
        self.scrollKeysDisposable?.dispose()
    }
    
    static func scrollObservableSmooth(textField: OverlayTextField, character: Character, yAxis: Int64, xAxis: Int64, frequencyMilliseconds: Int) -> Observable<Void> {
        return textField.distinctNSEventObservable
            .filter({ $0.type == .keyUp || $0.type == .keyDown })
            .filter({ $0.characters?.first == character })
            .flatMapLatest({ event -> Observable<Void> in
                if event.type == .keyUp {
                    // trackpad "release" event
                    // this prevents us from scrolling against the "rubber band" at the end of a scroll area
                    // unfortunately it causes the scroll to "glide" at the end, which may not be desirable
                    let scrollEventPhase4 = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
                    scrollEventPhase4.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
                    scrollEventPhase4.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
                    scrollEventPhase4.setDoubleValueField(.scrollWheelEventScrollPhase, value: 4)
                    scrollEventPhase4.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
                    scrollEventPhase4.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
                    scrollEventPhase4.post(tap: .cghidEventTap)
                    return Observable.just(Void())
                }
                

                // this scroll phase 128 signifies the start of a trackpad scroll
                // if an application did not receive this event, the scroll events below will not work
                // the application only needs to receive this event once.
                let scrollEventPhase128 = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
                scrollEventPhase128.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
                scrollEventPhase128.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
                scrollEventPhase128.setIntegerValueField(.scrollWheelEventScrollPhase, value: 128)
                scrollEventPhase128.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
                scrollEventPhase128.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
                scrollEventPhase128.post(tap: .cghidEventTap)
                
                // this event is the second event emitted.
                // if not present the final event (scroll phase 4) will not be allowed to emit (hence rubber banding will not work)
                let scrollEventPhase1 = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
                scrollEventPhase1.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
                scrollEventPhase1.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
                scrollEventPhase1.setIntegerValueField(.scrollWheelEventScrollPhase, value: 1)
                scrollEventPhase1.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: yAxis)
                scrollEventPhase1.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: xAxis)
                scrollEventPhase1.post(tap: .cghidEventTap)

                return Observable<Int>.interval(.milliseconds(frequencyMilliseconds), scheduler: MainScheduler.instance)
                    .map({ _ in Void() })
                    .do(onNext: { _ in
                        let scrollEventPhase2 = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
                        scrollEventPhase2.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
                        scrollEventPhase2.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
                        scrollEventPhase2.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
                        scrollEventPhase2.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: yAxis)
                        scrollEventPhase2.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: xAxis)
                        scrollEventPhase2.post(tap: .cghidEventTap)
                    })
            })
    }
    
    static func scrollObservableChunky(textField: OverlayTextField, character: Character, yAxis: Int, xAxis: Int, frequencyMilliseconds: Int) -> Observable<Void> {
        textField.distinctNSEventObservable
            .filter({ $0.type == .keyUp || $0.type == .keyDown })
            .filter({ $0.characters?.first == character })
            .flatMapLatest({ event -> Observable<Void> in
                if event.type == .keyUp {
                    return Observable.empty()
                }
                return Observable<Int>.interval(.milliseconds(frequencyMilliseconds), scheduler: MainScheduler.instance)
                    .startWith(1)
                    .map({ _ in Void() })
                    .do(onNext: { _ in
                        let event = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
                        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(yAxis))
                        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(xAxis))
                        event.post(tap: .cghidEventTap)
                    })
            })
    }
}
