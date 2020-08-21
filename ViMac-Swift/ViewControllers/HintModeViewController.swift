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

class HintModeViewController: ModeViewController, NSTextFieldDelegate {
    let applicationWindow: UIElement
    lazy var elements: Observable<UIElement> = elementObservable()
    lazy var inputListeningTextField = instantiateInputListeningTextField()
    var hintViews: [HintView]?
    let compositeDisposable = CompositeDisposable()
    var characterStack: [Character] = [Character]()

    init(applicationWindow: UIElement) {
        self.applicationWindow = applicationWindow
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        attachInputListeningTextField()
        
        let alphabetKeyDownObservable = inputListeningTextField.distinctNSEventObservable
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
        
        self.compositeDisposable.insert(observeEscKey())
        self.compositeDisposable.insert(observeDeleteKey())
        self.compositeDisposable.insert(observeSpaceKey())
        
        self.compositeDisposable.insert(
            elements.toArray()
                .observeOn(MainScheduler.instance)
                .subscribe(
                onSuccess: { [weak self] elements in
                    self?.onElementTraversalComplete(elements: elements.filter({ element in
                        let actionCount = (try? element.actionsAsStrings().count) ?? 0
                        let role = try? element.role()
                        return actionCount > 0
                    }))
                }, onError: { error in
                    print(error)
                })
        )
    }
    
    func elementObservable() -> Observable<UIElement> {
        let windowElements = Utils.getWindowElements(windowElement: applicationWindow)
        let menuBarElements = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        let extraMenuBarElements = Utils.traverseForExtraMenuBarItems()
        let notificationCenterElements = Utils.traverseForNotificationCenterItems()
        return Observable.merge(windowElements, menuBarElements, extraMenuBarElements, notificationCenterElements)
    }
    
    func onElementTraversalComplete(elements: [UIElement]) {
        let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count, hintCharacters: UserPreferences.HintMode.CustomCharactersProperty.read())
        
        let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()

        let hintViews: [HintView] = elements
            .enumerated()
            .map ({ (index, button) in
                
                let text = HintView(associatedElement: button, hintTextSize: CGFloat(textSize), hintText: hintStrings[index], typedHintText: "")
                
                let centerPositionOptional: NSPoint? = {
                    do {
                        guard let topLeftPositionFlipped: NSPoint = try button.attribute(.position),
                            let buttonSize: NSSize = try button.attribute(.size) else {
                            return nil
                        }
                        let topLeftPositionRelativeToScreen = Utils.toOrigin(point: topLeftPositionFlipped, size: text.frame.size)
                        guard let topLeftPositionRelativeToWindow = self.modeCoordinator?.windowController.window?.convertPoint(fromScreen: topLeftPositionRelativeToScreen) else {
                            return nil
                        }
                        let x = (topLeftPositionRelativeToWindow.x + (buttonSize.width / 2)) - (text.frame.size.width / 2)
                        let y = (topLeftPositionRelativeToWindow.y - (buttonSize.height) / 2) + (text.frame.size.height / 2)
                        
                        // buttonSize.width/height and topLeftPositionRelativeToScreen.x/y can be NaN
                        if x.isNaN || y.isNaN {
                            return nil
                        }
                        
                        return NSPoint(x: x, y: y)
                    } catch {
                        return nil
                    }
                }()

                guard let centerPosition = centerPositionOptional else {
                    return nil
                }
                
                text.frame.origin = centerPosition
                
                return text
            })
            .compactMap({ $0 })
        
        self.hintViews = hintViews

        for hintView in hintViews {
            self.view.addSubview(hintView)
        }
        
        self.inputListeningTextField.becomeFirstResponder()
    }
    
    func observeEscKey() -> Disposable {
        let escapeKeyDownObservable = inputListeningTextField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Escape && event.type == .keyDown
        })
        return escapeKeyDownObservable
            .bind(onNext: { [weak self] _ in
                self?.onEscape()
            })
    }
    
    func observeDeleteKey() -> Disposable {
        let deleteKeyDownObservable = inputListeningTextField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Delete && event.type == .keyDown
        })
        return deleteKeyDownObservable
            .bind(onNext: { [weak self] _ in
                guard let vc = self else {
                    return
                }
                vc.characterStack.popLast()
                vc.updateHints(typed: String(vc.characterStack))
            })
    }
    
    func observeSpaceKey() -> Disposable {
        let spaceKeyDownObservable = inputListeningTextField.distinctNSEventObservable.filter({ event in
            return event.keyCode == kVK_Space && event.type == .keyDown
        })
        return spaceKeyDownObservable
            .bind(onNext: { [weak self] _ in
                self?.rotateHints()
            })
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
    
    func instantiateInputListeningTextField() -> OverlayTextField {
        let tf = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        tf.stringValue = ""
        tf.isEditable = true
        tf.delegate = self
        return tf
    }
    
    func attachInputListeningTextField() {
        inputListeningTextField.overlayTextFieldDelegate = self
        self.view.addSubview(inputListeningTextField)
    }
    
}
