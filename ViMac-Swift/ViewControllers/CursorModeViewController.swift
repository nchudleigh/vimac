//
//  CursorModeViewController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import Carbon.HIToolbox

class CursorModeViewController: ModeViewController, NSTextFieldDelegate {
    let elements: Observable<UIElement>
    let textField = CursorActionSelectorTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    var hintViews: [HintView]?
    let compositeDisposable = CompositeDisposable()
    var characterStack: [Character] = [Character]()

    init(elements: Observable<UIElement>) {
        self.elements = elements
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        // for some reason setting the text field to hidden breaks hint updating after the first hint update.
        // selectorTextField.isHidden = true
        textField.overlayTextFieldDelegate = self
        self.view.addSubview(textField)
        
        let escapeKeyDownObservable = textField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Escape && event.type == .keyDown
        })
        
        let deleteKeyDownObservable = textField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Delete && event.type == .keyDown
        })
        
        let spaceKeyDownObservable = textField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Space && event.type == .keyDown
        })
        
        let alphabetKeyDownObservable = textField.distinctNSEventObservable
            .filter({ event in
                guard let character = event.characters?.first else {
                    return false
                }
                return character.isLetter && event.type == .keyDown
            })
        
        self.compositeDisposable.insert(
            alphabetKeyDownObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] event in
                    guard let vc = self,
                        let character = event.characters?.first else {
                        return
                    }

                    vc.characterStack.append(character)
                    let typed = String(vc.characterStack)
            
                    let matchingHints = vc.hintViews!.filter { hintView in
                        return hintView.stringValue.starts(with: typed.uppercased())
                    }

                    if matchingHints.count == 0 && typed.count > 0 {
                        vc.modeCoordinator?.exitMode()
                        return
                    }
            
                    if matchingHints.count == 1 {
                        let matchingHint = matchingHints.first!
                        let buttonOptional = matchingHint.associatedButton
                        guard let button = buttonOptional else {
                            vc.modeCoordinator?.exitMode()
                            return
                        }
            
                        var buttonPositionOptional: NSPoint?
                        var buttonSizeOptional: NSSize?
                        do {
                            buttonPositionOptional = try button.attribute(.position)
                            buttonSizeOptional = try button.attribute(.size)
                        } catch {
                            vc.modeCoordinator?.exitMode()
                            return
                        }
            
                        guard let buttonPosition = buttonPositionOptional,
                            let buttonSize = buttonSizeOptional else {
                                vc.modeCoordinator?.exitMode()
                                return
                        }
            
                        let centerPositionX = buttonPosition.x + (buttonSize.width / 2)
                        let centerPositionY = buttonPosition.y + (buttonSize.height / 2)
                        let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)
            
                        Utils.moveMouse(position: centerPosition)
                        
                        if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                            Utils.rightClickMouse(position: centerPosition)
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                            Utils.doubleLeftClickMouse(position: centerPosition)
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.option.rawValue == NSEvent.ModifierFlags.option.rawValue) {
                        } else {
                            Utils.leftClickMouse(position: centerPosition)
                        }
                        vc.modeCoordinator?.exitMode()
                        return
                    }
            
                    // update hints to reflect new typed text
                    vc.updateHints(typed: typed)
                })
        )
        
        self.compositeDisposable.insert(
            escapeKeyDownObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.onEscape()
        }))
        
        self.compositeDisposable.insert(
            deleteKeyDownObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let vc = self else {
                        return
                    }
                    vc.characterStack.popLast()
                    vc.updateHints(typed: String(vc.characterStack))
        }))
        
        self.compositeDisposable.insert(
            spaceKeyDownObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let vc = self else {
                        return
                    }
                    vc.rotateHints()
        }))
        
        
        self.compositeDisposable.insert(
            elements.toArray()
                .observeOn(MainScheduler.instance)
                .subscribe(
                onSuccess: { elements in
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
                                let positionRelativeToWindow = self.modeCoordinator!.windowController.window!.convertPoint(fromScreen: positionRelativeToScreen)
                                text.associatedButton = button
                                text.frame.origin = positionRelativeToWindow
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
                    print(error)
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

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.compositeDisposable.dispose()
    }
}
