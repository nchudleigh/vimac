//
//  HintModeController.swift
//  Vimac
//
//  Created by Dexter Leng on 15/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import os

extension NSEvent {
    static func localEventMonitor(matching: EventTypeMask) -> Observable<NSEvent> {
        Observable.create({ observer in
            let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: matching, handler: { event -> NSEvent? in
                observer.onNext(event)
                // return nil to prevent the event from being dispatched
                // this removes the "doot doot" sound when typing with CMD / CTRL held down
                return nil
            })!

            let cancel = Disposables.create {
                NSEvent.removeMonitor(keyMonitor)
            }
            return cancel
        })
    }
}

// a view controller that has a single view controller child that can be swapped out.
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
    
    func setChildViewController(_ vc: NSViewController) {
        assert(self.children.count <= 1)
        removeChildViewController()

        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
    }

    func removeChildViewController() {
        guard let childVC = self.children.first else { return }
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}

class HintModeController {
    let app: NSRunningApplication
    let window: Element
    private var state = HintModeState.initialState
    private let startTime = CFAbsoluteTimeGetCurrent()
    private let disposeBag = DisposeBag()
    
    // preferences
    let hintCharacters = UserPreferences.HintMode.CustomCharactersProperty.read()
    let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()
    
    var windowController: OverlayWindowController!
    var contentViewController: ContentViewController!
    var hintsViewController: HintsViewController!
    let inputListener = HintModeInputListener()
    
    init(app: NSRunningApplication, window: Element) {
        self.app = app
        self.window = window
    }

    func activate() {
        let focusedWindowFrame: NSRect = GeometryUtils.convertAXFrameToGlobal(window.frame)
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindowFrame)
        
        self.windowController = OverlayWindowController()
        self.contentViewController = ContentViewController()
        self.windowController.window?.contentViewController = self.contentViewController
        self.windowController.fitToFrame(screenFrame)
        self.windowController.showWindow(nil)
        self.windowController.window?.makeKeyAndOrderFront(nil)
        
        handleEvent(.activate)
    }
    
    func deactivate() {
        handleEvent(.deactivate)
    }
    
    private func handleEvent(_ event: HintModeState.Event) {
        let command = self.state.handleEvent(event)
        switch command {
        case .loadHints:
            queryHints(
                onSuccess: { [weak self] hints in
                    self?.handleEvent(.hintsFetched(hints: hints))
                },
                onError: { [weak self] _ in
                    self?.handleEvent(.deactivate)
                }
            )
        case .drawHints:
            drawHints()
            setupInputListener()
        case .updateInput:
            updateInput()
        case .perform(let hint, let action):
            self._deactivate()
            performHintAction(hint, action: action)
        case .eraseHints:
            self._deactivate()
        case .rotateHints:
            self.rotateHints()
        default:
            return
        }
    }
    
    private func queryHints(onSuccess: @escaping ([Hint]) -> Void, onError: @escaping (Error) -> Void) {
        HintModeQueryService.init(app: app, window: window, hintCharacters: hintCharacters).perform()
            .toArray()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { _ in self.logQueryTime() })
            .do(onError: { e in self.logError(e) })
            .subscribe(
                onSuccess: { onSuccess($0) },
                onError: { onError($0) }
            )
            .disposed(by: disposeBag)
    }
    
    private func drawHints() {
        switch state {
        case .activated(let hints, let input):
            self.hintsViewController = HintsViewController(hints: hints, textSize: CGFloat(textSize), hintCharacters: hintCharacters, typed: input)
            self.contentViewController.setChildViewController(self.hintsViewController)
            return
        default:
            return
        }
    }
    
    private func updateInput() {
        switch state {
        case .activated(_, let input):
            self.hintsViewController.updateTyped(typed: input)
            return
        default:
            return
        }
    }
    
    private func setupInputListener() {
        NSEvent.localEventMonitor(matching: .keyDown)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleEvent(.keyPress(event: event))
            })
            .disposed(by: disposeBag)
    }
    
    private func performHintAction(_ hint: Hint, action: HintAction) {
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
    
    private func _deactivate() {
        self.contentViewController?.view.removeFromSuperview()
        self.windowController?.window?.contentViewController = nil
        self.windowController?.close()
    }
    
    private func rotateHints() {
        hintsViewController.rotateHints()
    }
    
    private func logQueryTime() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime
        os_log("[Hint mode] query time: %@", log: Log.accessibility, String(describing: timeElapsed))
    }
    
    private func logError(_ e: Error) {
        os_log("[Hint mode] query error: %@", log: Log.accessibility, String(describing: e))
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
}
