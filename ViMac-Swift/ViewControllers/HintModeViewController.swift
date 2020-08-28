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
    let applicationWindow: UIElement
    lazy var elements: Single<[UIElement]> = elementObservable().toArray()
    lazy var inputListeningTextField = instantiateInputListeningTextField()
    var hintViews: [HintView]?
    let compositeDisposable = CompositeDisposable()
    let inputListener = HintModeInputListener()
    var characterStack: [Character] = [Character]()
    let whitelistedActions = Set(UserPreferences.HintMode.ActionsProperty.read())
    let startTime = CFAbsoluteTimeGetCurrent()

    init(applicationWindow: UIElement) {
        self.applicationWindow = applicationWindow
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(inputListeningTextField)
        
        observeLetterKeyDown()
        observeEscKey()
        observeDeleteKey()
        observeSpaceKey()
        
        self.compositeDisposable.insert(observeElements())
    }
    
    func elementObservable() -> Observable<UIElement> {
        let windowElements = Utils.singleToObservable(single: queryWindowElementsSingle())
        let menuBarElements = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        let extraMenuBarElements = Utils.traverseForExtraMenuBarItems()
        let notificationCenterElements = Utils.traverseForNotificationCenterItems()
        return Observable.merge(windowElements, menuBarElements, extraMenuBarElements, notificationCenterElements)
    }
    
    func queryWindowElementsSingle() -> Single<[UIElement]> {
        return Single.create(subscribe: { event in
            let thread = Thread.init(block: {
                let service = QueryWindowService.init(windowElement: self.applicationWindow)
                let elements = try? service.perform()
                event(.success(elements ?? []))
            })
            thread.start()
            return Disposables.create {
                thread.cancel()
            }
        })
    }
    
    func onLetterKeyDown(event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers?.first else {
            return
        }

        self.characterStack.append(character)
        let typed = String(self.characterStack)

        let matchingHints = self.hintViews!.filter { hintView in
            return hintView.hintTextView!.stringValue.starts(with: typed.uppercased())
        }

        if matchingHints.count == 0 && typed.count > 0 {
            self.modeCoordinator?.exitMode()
            return
        }

        if matchingHints.count == 1 {
            let matchingHint = matchingHints.first!
            let button = matchingHint.associatedElement

            let buttonPositionOptional: NSPoint? = try? button.attribute(.position)
            let buttonSizeOptional: NSSize? = try? button.attribute(.size)

            guard let buttonPosition = buttonPositionOptional,
                let buttonSize = buttonSizeOptional else {
                    self.modeCoordinator?.exitMode()
                    return
            }

            let centerPositionX = buttonPosition.x + (buttonSize.width / 2)
            let centerPositionY = buttonPosition.y + (buttonSize.height / 2)
            let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)

            // close the window before performing click(s)
            // Chrome's bookmark bar doesn't let you right click if Chrome is not the active window
            self.modeCoordinator?.exitMode()
            
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
        self.updateHints(typed: typed)
    }
    
    func observeLetterKeyDown() {
        inputListener.observeLetterKeyDown(onEvent: { [weak self] event in
            self?.onLetterKeyDown(event: event)
        })
    }
    
    func observeEscKey() {
        inputListener.observeEscapeKey(onEvent: { [weak self] _ in
            self?.onEscape()
        })
    }
    
    func observeDeleteKey() {
        inputListener.observeDeleteKey(onEvent: { [weak self] _ in
            guard let vc = self else {
                return
            }
            vc.characterStack.popLast()
            vc.updateHints(typed: String(vc.characterStack))
        })
    }
    
    func observeSpaceKey() {
        inputListener.observeSpaceKey(onEvent: { [weak self] _ in
            self?.rotateHints()
        })
    }
    
    func observeElements() -> Disposable {
        return elements
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] elements in
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - self!.startTime
                    os_log("[Hint mode] query time: %@", log: Log.accessibility, String(describing: timeElapsed))
                    
                    self?.onElementTraversalComplete(elements: elements.filter({ element in
                        let actions = try? element.actionsAsStrings()
                        var isAllowed = false

                        if let actions = actions {
                            let containsWhitelistedAction = Set(actions).intersection(self!.whitelistedActions).count > 0
                            isAllowed = containsWhitelistedAction
                        }
                        return isAllowed
                    }))
                },
                onError: { error in
                    print(error)
                }
            )
    }
    
    func onElementTraversalComplete(elements: [UIElement]) {
        let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count, hintCharacters: UserPreferences.HintMode.CustomCharactersProperty.read())
        
        let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()

        let hintViews: [HintView] = elements
            .enumerated()
            .map ({ (index, element) in
                return instantiateHintView(associatedElement: element, textSize: CGFloat(textSize), text: hintStrings[index])
            })
            .compactMap({ $0 })
        
        self.hintViews = hintViews

        for hintView in hintViews {
            self.view.addSubview(hintView)
        }
        
        self.inputListeningTextField.becomeFirstResponder()
    }
    
    func instantiateHintView(associatedElement: UIElement, textSize: CGFloat, text: String) -> HintView? {
        let text = HintView(associatedElement: associatedElement, hintTextSize: CGFloat(textSize), hintText: text, typedHintText: "")
        
        let centerPositionOptional: NSPoint? = {
            do {
                guard let topLeftPositionFlipped: NSPoint = try associatedElement.attribute(.position),
                    let buttonSize: NSSize = try associatedElement.attribute(.size) else {
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
    
    func instantiateInputListeningTextField() -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = ""
        textField.isEditable = true
        return textField
    }
}
