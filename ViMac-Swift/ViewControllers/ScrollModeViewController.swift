//
//  ScrollModeViewController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class ScrollModeViewController: ModeViewController, NSTextFieldDelegate {
    let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    let scrollModeDisposable = CompositeDisposable()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        //textField.isHidden = true
        textField.overlayTextFieldDelegate = self
        self.view.addSubview(textField)
        
        // get scroll area mouse is hovering over for D U scrolling,
        // which are relative to scroll area height.
        var scrollAreaHeight: CGFloat = 0
        if let applicationWindow = Utils.getCurrentApplicationWindowManually() {
            let scrollAreas = Utils.traverseUIElementForScrollAreas(rootElement: applicationWindow)
            if scrollAreas.count > 0 {
                let mouseLocation = NSEvent.mouseLocation
                for scrollArea in scrollAreas {
                    do {
                        if let position: NSPoint = try scrollArea.attribute(.position),
                            let size: NSSize = try scrollArea.attribute(.size) {
                            let frame = NSRect(origin: Utils.toOrigin(point: position, size: size), size: size)
                            if frame.contains(mouseLocation) {
                                scrollAreaHeight = size.height
                                break
                            }
                        }
                    } catch {
                    }
                }
            }
        }
        
        let halfScrollAreaHeight = scrollAreaHeight / 2
        
        let scrollSensitivity = Int64(UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey))
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableSmooth(textField: textField, character: "j", yAxis: -1 * scrollSensitivity, xAxis: 0, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableSmooth(textField: textField, character: "k", yAxis: scrollSensitivity, xAxis: 0, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableSmooth(textField: textField, character: "h", yAxis: 0, xAxis: scrollSensitivity, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableSmooth(textField: textField, character: "l", yAxis: 0, xAxis: -1 * scrollSensitivity, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableChunky(textField: textField, character: "d", yAxis: Int32(-1 * halfScrollAreaHeight), xAxis: 0, frequencyMilliseconds: 200)
                .subscribe()
        )
        
        scrollModeDisposable.insert(
            AccessibilityObservables.scrollObservableChunky(textField: textField, character: "u", yAxis: Int32(halfScrollAreaHeight), xAxis: 0, frequencyMilliseconds: 200)
                .subscribe()
        )
    }
    
    override func viewDidDisappear() {
        self.scrollModeDisposable.dispose()
    }
}
