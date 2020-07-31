//
//  HintModeViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import Carbon.HIToolbox
import os

class HintModeViewController: ModeViewController, NSTextFieldDelegate {
    let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    var hintViews: [HintView]?
    let compositeDisposable = CompositeDisposable()
    var characterStack: [Character] = [Character]()
    let startTime = CFAbsoluteTimeGetCurrent()
    
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
                guard let character = event.charactersIgnoringModifiers?.first else {
                    return false
                }
                return character.isLetter && event.type == .keyDown
            })
        
        self.compositeDisposable.insert(
            alphabetKeyDownObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] event in
                    guard let vc = self,
                        let character = event.charactersIgnoringModifiers?.first else {
                        return
                    }

                    vc.characterStack.append(character)
                    let typed = String(vc.characterStack)
            
                    let matchingHints = vc.hintViews!.filter { hintView in
                        return hintView.hintTextView!.stringValue.starts(with: typed.uppercased())
                    }

                    if matchingHints.count == 0 && typed.count > 0 {
                        vc.modeCoordinator?.exitMode()
                        return
                    }
            
                    if matchingHints.count == 1 {
                        let matchingHint = matchingHints.first!
                        let button = matchingHint.associatedElement
            
                        let buttonPositionOptional: NSPoint? = try? button.attribute(.position)
                        let buttonSizeOptional: NSSize? = try? button.attribute(.size)
            
                        guard let buttonPosition = buttonPositionOptional,
                            let buttonSize = buttonSizeOptional else {
                                vc.modeCoordinator?.exitMode()
                                return
                        }
            
                        let centerPositionX = buttonPosition.x + (buttonSize.width / 2)
                        let centerPositionY = buttonPosition.y + (buttonSize.height / 2)
                        let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)
            
                        // close the window before performing click(s)
                        // Chrome's bookmark bar doesn't let you right click if Chrome is not the active window
                        vc.modeCoordinator?.exitMode()
                        
                        Utils.moveMouse(position: centerPosition)
                        
                        if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                            Utils.rightClickMouse(position: centerPosition)
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                            Utils.doubleLeftClickMouse(position: centerPosition)
                        } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.control.rawValue == NSEvent.ModifierFlags.control.rawValue) {
                        } else {
                            Utils.leftClickMouse(position: centerPosition)
                        }
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
        
        self.compositeDisposable.insert(observeWindowElements())
    }
    
    func onElementTraversalComplete(elements: [Element]) {
        let elements = elements
            .filter({ element in
                let actionCount = (try? element.cachedUIElement.actionsAsStrings().count) ?? 0
                return actionCount > 0
            })
        
        let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count, hintCharacters: UserPreferences.HintMode.CustomCharactersProperty.read())
        
        let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()

        let hintViews: [HintView] = elements
            .enumerated()
            .map ({ x in
                return instantiateHintView(element: x.element, hintText: hintStrings[x.offset], textSize: textSize)
            })
            .compactMap({ $0 })
        
        self.hintViews = hintViews

        for hintView in hintViews {
            self.view.addSubview(hintView)
        }
        
        self.textField.becomeFirstResponder()
    }
    
    func updateHints(typed: String) {
        guard let hintViews = self.hintViews else {
            self.modeCoordinator?.exitMode()
            return
        }

        hintViews.forEach { hintView in
            hintView.isHidden = true
            if hintView.hintTextView!.stringValue.starts(with: typed.uppercased()) {
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
        for hintView in shuffledHintViews {
            self.view.addSubview(hintView)
        }
        self.hintViews = shuffledHintViews
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.compositeDisposable.dispose()
    }
    
    func observeWindowElements() -> Disposable {
        let activeWindowRawElement = Utils.getCurrentApplicationWindowManually()?.element
        let activeWindowElement = Element.init(axUIElement: activeWindowRawElement!)
        let elementsObservable: Single<[Element]> = createWindowElementsObservable(windowElement: activeWindowElement)
        return elementsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] elements in
                self?.onElementTraversalComplete(elements: elements)
        })
    }
    
    func createWindowElementsObservable(windowElement: Element) -> Single<[Element]> {
        return Single.create { observer in
            let queryService = HintModeElementQueryService(windowElement: windowElement)
            queryService.query(onComplete: { elements in
                observer(SingleEvent.success(elements))
            })

            return Disposables.create {
                // hold a reference to queryService so it isn't GC'd
                return queryService
            }
        }
    }
    
    private func instantiateHintView(element: Element, hintText: String, textSize: Float) -> HintView? {
        let text = HintView(associatedElement: element.cachedUIElement, hintTextSize: CGFloat(textSize), hintText: hintText, typedHintText: "")
        let position = element.position()!
        let size = element.size()!
        
        let centerPositionOptional: NSPoint? = {
            let topLeftPositionFlipped: NSPoint = position
            let topLeftPositionRelativeToScreen = Utils.toOrigin(point: topLeftPositionFlipped, size: text.frame.size)
            let topLeftPositionRelativeToWindow = self.modeCoordinator!.windowController.window!.convertPoint(fromScreen: topLeftPositionRelativeToScreen)
            let x = (topLeftPositionRelativeToWindow.x + (size.width / 2)) - (text.frame.size.width / 2)
            let y = (topLeftPositionRelativeToWindow.y - (size.height) / 2) + (text.frame.size.height / 2)
            
            // buttonSize.width/height and topLeftPositionRelativeToScreen.x/y can be NaN
            if x.isNaN || y.isNaN {
                return nil
            }
            
            return NSPoint(x: x, y: y)
        }()

        guard let centerPosition = centerPositionOptional else {
            return nil
        }
        
        text.frame.origin = centerPosition
        
        return text
    }
}
