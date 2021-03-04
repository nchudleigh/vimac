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

class ContentViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
    }
}

struct Hint {
    let element: Element
    let text: String
}

enum HintAction {
    case leftClick
    case rightClick
    case doubleLeftClick
}

class HintMode: NSObject, NSWindowDelegate {
    let app: NSRunningApplication
    let window: Element

    private let inputListener = HintModeInputListener()
    private let compositeDisposable = CompositeDisposable()
    weak var delegate: HintModeDelegate?
    
    // preferences
    let possibleHintCharacters = UserPreferences.HintMode.CustomCharactersProperty.read()
    let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()
    
    // states
    enum State {
        case unactivated
        case loading
        case active
        case error
    }
    
    var state: State = .unactivated
    
    // state specific information - should refactor to a state machine
    var _windowController: OverlayWindowController?
    var _loadingViewController: NSViewController?
    let startTime = CFAbsoluteTimeGetCurrent()
    var characterStack: [Character] = [Character]()
    
    var hints: [Hint]?
    var hintsViewController: HintsViewController?
    
    init(app: NSRunningApplication, window: Element) {
        self.app = app
        self.window = window
    }
    
    // activate mode, returns success of activation
    // cannot be activated more than once.
    func activate() -> Bool {
        if state != .unactivated {
            return false
        }

        let focusedWindowFrame: NSRect = GeometryUtils.convertAXFrameToGlobal(window.frame)
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindowFrame)
        
        let windowController = OverlayWindowController()
        windowController.window?.delegate = self
        windowController.window?.contentViewController = ContentViewController()
        
        self._windowController = windowController
        self._windowController?.fitToFrame(screenFrame)
        self._windowController?.showWindow(nil)
        self._windowController?.window?.makeKeyAndOrderFront(nil)
        
        self.state = .loading
        
        let disposable = HintModeQueryService.init(app: app, window: window, hintCharacters: possibleHintCharacters).perform()
            .toArray()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { _ in self.logQueryTime() })
            .do(onError: { e in self.logError(e) })
            .subscribe(
                onSuccess: { self.onHintQueryCompleted(hints: $0) },
                onError: { _ in self.onHintQueryError() }
            )
        _ = self.compositeDisposable.insert(disposable)
        
        return true
    }
    
    func onHintQueryCompleted(hints: [Hint]) {
        guard let windowController = _windowController else { return }
        
        self.state = .active
        self.hints = hints
        
        self.hintsViewController = HintsViewController(hints: self.hints!, textSize: CGFloat(textSize), hintCharacters: possibleHintCharacters)
        
        windowController.contentViewController!.addChild(self.hintsViewController!)
        self.hintsViewController!.view.frame = windowController.contentViewController!.view.frame
        windowController.contentViewController!.view.addSubview(self.hintsViewController!.view)
        
        observeLetterKeyDown()
        observeEscKey()
        observeDeleteKey()
        observeSpaceKey()
    }
    
    func onHintQueryError() {
        self.deactivate()
    }
    
    func deactivate() {
        self.hintsViewController = nil
        self._windowController?.close()
        compositeDisposable.dispose()
        self.delegate?.onHintModeExit()
    }
    
    deinit {
        compositeDisposable.dispose()
    }

    // fun fact, focusedWindow need not return "AXWindow"...
    private func focusedWindow(app: NSRunningApplication) -> Element? {
        let axAppOptional = Application.init(app)
        guard let axApp = axAppOptional else { return nil }
        
        let axWindowOptional: UIElement? = try? axApp.attribute(.focusedWindow)
        guard let axWindow = axWindowOptional else { return nil }
        
        return Element.initialize(rawElement: axWindow.element)
    }
    
    private func activeScreenFrame(focusedWindowFrame: NSRect) -> NSRect {
        // When the focused window is in full screen mode in a secondary display,
        // NSScreen.main will point to the primary display.
        // this is a workaround.
        var activeScreen = NSScreen.main!
        var maxArea: CGFloat = 0
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(focusedWindowFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                activeScreen = screen
            }
        }
        return activeScreen.frame
    }
    
    func onLetterKeyDown(event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers?.first else { return }
        guard let hints = hints else { return }
        
        self.characterStack.append(character)
        let typed = String(self.characterStack)

        let matchingHints = hints.filter { $0.text.starts(with: typed.uppercased()) }
    
        if matchingHints.count == 0 && typed.count > 0 {
            self.deactivate()
            return
        }

        if matchingHints.count == 1 {
            let hint = matchingHints.first!
            
            // close the window before performing click(s)
            // Chrome's bookmark bar doesn't let you right click if Chrome is not the active window
            self.deactivate()

            let originalMousePosition: NSPoint = {
                let invertedPos = NSEvent.mouseLocation
                let frame = GeometryUtils.convertAXFrameToGlobal(
                    NSRect(
                        origin: invertedPos,
                        size: NSSize.zero
                    )
                )
                return frame.origin
            }()
            let action: HintAction = {
                if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                    return .rightClick
                } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                    return .doubleLeftClick
                } else {
                    return .leftClick
                }
            }()
            performHintAction(hint, action: action)
            
            Utils.moveMouse(position: originalMousePosition)
        }

        // update hints to reflect new typed text
        self.updateHints(typed: typed)
    }
    
    func performHintAction(_ hint: Hint, action: HintAction) {
        let element = hint.element

        let frame = element.clippedFrame ?? element.frame
        let position = frame.origin
        let size = frame.size

        let centerPositionX = position.x + (size.width / 2)
        let centerPositionY = position.y + (size.height / 2)
        let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)

        Utils.moveMouse(position: centerPosition)
        
        switch action {
        case .leftClick:
            Utils.leftClickMouse(position: centerPosition)
        case .rightClick:
            Utils.rightClickMouse(position: centerPosition)
        case .doubleLeftClick:
            Utils.doubleLeftClickMouse(position: centerPosition)
        }
    }
    
    func observeLetterKeyDown() {
        inputListener.observeKeyDown(onEvent: { [weak self] event in
            self?.onLetterKeyDown(event: event)
        })
    }
    
    func observeEscKey() {
        inputListener.observeEscapeKey(onEvent: { [weak self] _ in
            self?.deactivate()
        })
    }
    
    func observeDeleteKey() {
        inputListener.observeDeleteKey(onEvent: { [weak self] _ in
            guard let vc = self else {
                return
            }
            _ = vc.characterStack.popLast()
            vc.updateHints(typed: String(vc.characterStack))
        })
    }
    
    func observeSpaceKey() {
        inputListener.observeSpaceKey(onEvent: { [weak self] _ in
            self?.rotateHints()
        })
    }
    
    func logQueryTime() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime
        os_log("[Hint mode] query time: %@", log: Log.accessibility, String(describing: timeElapsed))
    }
    
    func logError(_ e: Error) {
        os_log("[Hint mode] query error: %@", log: Log.accessibility, String(describing: e))
    }
    
    func updateHints(typed: String) {
        guard let hintsVC = hintsViewController else { return }
        hintsVC.updateTyped(typed: typed)
    }
    
    func rotateHints() {
        guard let hintsVC = hintsViewController else { return }
        hintsVC.rotateHints()
    }
    
    func hideMouse() {
        HideCursorGlobally.hide()
    }
    
    func showMouse() {
        HideCursorGlobally.unhide()
    }
}

extension HintMode {    
    func windowDidResignKey(_ notification: Notification) {
        self.deactivate()
    }
}

protocol HintModeDelegate: class {
    func onHintModeExit()
}
