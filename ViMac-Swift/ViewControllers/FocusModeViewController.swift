//
//  FocusModeViewController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import AXSwift

class FocusModeViewController: ModeViewController, NSTextFieldDelegate {
    var elements: Observable<UIElement>?
    var hintViews: [HintView]?
    let textField = FocusSelectorTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    let compositeDisposable = CompositeDisposable()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let elements = self.elements else {
            self.modeCoordinator?.exitMode()
            return
        }
        
        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        // for some reason setting the text field to hidden breaks hint updating after the first hint update.
        // textField.isHidden = true
        textField.overlayTextFieldDelegate = self
        self.view.addSubview(textField)
        
        self.compositeDisposable.insert(
            elements.toArray()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { elements in
                    let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count)

                    let hintViews: [HintView] = elements
                        .enumerated()
                        .map ({ (index, button) in
                            let positionFlippedOptional: NSPoint? = {
                                do {
                                    return try button.attribute(.position)
                                } catch {
                                    return nil
                                }
                            }()

                            if let positionFlipped = positionFlippedOptional {
                                let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                                text.initializeHint(hintText: hintStrings[index], typed: "")
                                let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                                let positionRelativeToWindow = self.modeCoordinator?.windowController.window?.convertPoint(fromScreen: positionRelativeToScreen)
                                text.associatedButton = button
                                text.frame.origin = positionRelativeToWindow!
                                text.zIndex = index
                                return text
                            }
                            return nil })
                        .compactMap({ $0 })
                    
                    self.hintViews = hintViews
                    
                    for hintView in hintViews {
                        self.view.addSubview(hintView)
                    }
                    
                    self.textField.becomeFirstResponder()
                    
                }, onError: { error in
                    
                })
        )
    }
    
    func updateHints(typed: String) {
        guard let hintViews = self.hintViews else {
            self.modeCoordinator?.exitMode()
            return
        }

        hintViews.forEach { hintView in
            hintView.isHidden = true
            if hintView.stringValue.starts(with: typed.uppercased()) {
                hintView.updateTypedText(typed: typed)
                hintView.isHidden = false
            }
        }
    }
    
    // randomly rotate hints
    // ideally we group them into clusters of intersecting hints and rotate within those clusters
    // but this is just a quick fast hack
    func rotateHints() {
        guard let hintViews = self.hintViews else {
            self.modeCoordinator?.exitMode()
            return
        }
        
        for hintView in hintViews {
            hintView.removeFromSuperview()
        }
        
        let shuffledHintViews = hintViews.shuffled()
        for (index, hintView) in shuffledHintViews.enumerated() {
            hintView.zIndex = index
            self.view.addSubview(hintView)
        }
        self.hintViews = shuffledHintViews
    }
    
    func controlTextDidChange(_ obj: Notification) {
        guard let hintViews = self.hintViews else {
            return
        }
        
        let typed = self.textField.stringValue

        if let lastCharacter = typed.last {
            if lastCharacter == " " {
                textField.stringValue = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                self.rotateHints()
                return
            }
        }
        
        let matchingHints = hintViews.filter { hintView in
            return hintView.stringValue.starts(with: typed.uppercased())
        }
        
        if matchingHints.count == 0 && typed.count > 0 {
            self.modeCoordinator?.exitMode()
            return
        }
        
        if matchingHints.count == 1 {
            // TODO: remove hints from vc
            let matchingHint = matchingHints.first!
            let elementOptional = matchingHint.associatedButton
            guard let element = elementOptional else {
                self.modeCoordinator?.exitMode()
                return
            }

            do {
                try element.setAttribute(.focused, value: true)
            } catch {
            }
            self.modeCoordinator?.exitMode()
            return
        }
        
        // update hints to reflect new typed text
        self.updateHints(typed: typed)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.compositeDisposable.dispose()
    }
}
