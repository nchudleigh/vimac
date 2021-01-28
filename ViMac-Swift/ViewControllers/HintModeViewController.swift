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
    let app: NSRunningApplication
    let window: Element
    lazy var elements: Single<[Element]> = elementObservable().toArray()
    lazy var inputListeningTextField = instantiateInputListeningTextField()
    var hintViews: [HintView]?
    let compositeDisposable = CompositeDisposable()
    let inputListener = HintModeInputListener()
    var characterStack: [Character] = [Character]()
    let originalMousePosition = NSEvent.mouseLocation
    let startTime = CFAbsoluteTimeGetCurrent()

    init(app: NSRunningApplication, window: Element) {
        self.app = app
        self.window = window
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
        
        hideMouse()
    }
    
    func elementObservable() -> Observable<Element> {
        return Utils.eagerConcat(observables: [
            Utils.singleToObservable(single: queryWindowElementsSingle()),
            Utils.singleToObservable(single: queryMenuBarSingle()),
            Utils.singleToObservable(single: queryMenuBarExtrasSingle()),
            Utils.singleToObservable(single: queryNotificationCenterSingle())
        ])
    }
    
    func queryWindowElementsSingle() -> Single<[Element]> {
        return Single.create(subscribe: { [weak self] event in
            guard let self = self else {
                event(.success([]))
                return Disposables.create()
            }
            
            let thread = Thread.init(block: {
                let service = QueryWindowService.init(app: self.app, window: self.window)
                let elements = try? service.perform()
                event(.success(elements ?? []))
            })
            thread.start()
            return Disposables.create {
                thread.cancel()
            }
        })
    }
    
    func queryMenuBarSingle() -> Single<[Element]> {
        return Single.create(subscribe: { [weak self] event in
            guard let self = self else {
                event(.success([]))
                return Disposables.create()
            }
            
            let thread = Thread.init(block: {
                // as of 28e46b9cbe9a38e7c43c1eb1f0d8953d99bc5ef9,
                // when one activates hint mode when the Vimac preference page is frontmost,
                // the app crashes with EXC_BAD_INSTRUCTION when retrieving menu bar items attributes through Element.initialize
                // I suspect that threading is the cause of crashing when reading attributes from your own app
                let isVimac = self.app.bundleIdentifier == Bundle.main.bundleIdentifier
                if isVimac {
                    event(.success([]))
                    return
                }
                
                let service = QueryMenuBarItemsService.init(app: self.app)
                let elements = try? service.perform()
                event(.success(elements ?? []))
            })
            thread.start()
            return Disposables.create {
                thread.cancel()
            }
        })
    }
    
    func queryMenuBarExtrasSingle() -> Single<[Element]> {
        return Single.create(subscribe: { event in
            let thread = Thread.init(block: {
                let service = QueryMenuBarExtrasService.init()
                let elements = try? service.perform()
                event(.success(elements ?? []))
            })
            thread.start()
            return Disposables.create {
                thread.cancel()
            }
        })
    }
    
    func queryNotificationCenterSingle() -> Single<[Element]> {
        return Single.create(subscribe: { event in
            let thread = Thread.init(block: {
                let service = QueryNotificationCenterItemsService.init()
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
        guard let character = event.charactersIgnoringModifiers?.first else { return }
        guard let hintViews = self.hintViews else { return }

        self.characterStack.append(character)
        let typed = String(self.characterStack)

        let matchingHints = hintViews.filter { hintView in
            return hintView.hintTextView!.stringValue.starts(with: typed.uppercased())
        }

        if matchingHints.count == 0 && typed.count > 0 {
            self.modeCoordinator?.exitMode()
            return
        }

        if matchingHints.count == 1 {
            let matchingHint = matchingHints.first!
            let element = matchingHint.associatedElement

            let frame = element.clippedFrame ?? element.frame
            let position = frame.origin
            let size = frame.size

            let centerPositionX = position.x + (size.width / 2)
            let centerPositionY = position.y + (size.height / 2)
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
            
            revertMouseLocation()
            return
        }

        // update hints to reflect new typed text
        self.updateHints(typed: typed)
    }
    
    func observeLetterKeyDown() {
        inputListener.observeKeyDown(onEvent: { [weak self] event in
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
                    
                    self?.onElementTraversalComplete(elements: elements)
                },
                onError: { error in
                    print(error)
                }
            )
    }
    
    func onElementTraversalComplete(elements: [Element]) {
        let hintStrings = AlphabetHints().hintStrings(linkCount: elements.count, hintCharacters: UserPreferences.HintMode.CustomCharactersProperty.read())
        
        let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()
        let textOffset = UserPreferences.HintMode.TextOffsetProperty.readAsPoint()

        let hintViews: [HintView] = elements
            .enumerated()
            .map ({ (index, element) in
                return instantiateHintView(associatedElement: element, textSize: CGFloat(textSize), textOffset: textOffset, text: hintStrings[index])
            })
            .compactMap({ $0 })
        
        self.hintViews = hintViews

        for hintView in hintViews {
            self.view.addSubview(hintView)
        }
        
        self.inputListeningTextField.becomeFirstResponder()
    }
    
    func instantiateHintView(associatedElement: Element, textSize: CGFloat, textOffset: CGPoint, text: String) -> HintView? {
        let text = HintView(associatedElement: associatedElement, hintTextSize: CGFloat(textSize), hintText: text, typedHintText: "")
        
        let centerPositionOptional: NSPoint? = {
            do {
                let frame = associatedElement.clippedFrame ?? associatedElement.frame
                let topLeftPositionFlipped: NSPoint = frame.origin
                let buttonSize: NSSize = frame.size
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
                
                return NSPoint(x: x + textOffset.x, y: y + textOffset.y)
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
    
    func hideMouse() {
        HideCursorGlobally.hide()
    }
    
    func showMouse() {
        HideCursorGlobally.unhide()
    }
    
    func revertMouseLocation() {
        Utils.moveMouse(position: Utils.toOrigin(point: originalMousePosition, size: NSSize.zero))
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.compositeDisposable.dispose()
        
        showMouse()
    }
    
    func instantiateInputListeningTextField() -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = ""
        textField.isEditable = true
        return textField
    }
}
