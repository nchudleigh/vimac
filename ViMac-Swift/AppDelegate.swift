//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import MASShortcut
import os
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static let NORMAL_MODE_TEXT_FIELD_TAG = 1
    static let HINT_SELECTOR_TEXT_FIELD_TAG = 2
    static let SCROLL_MODE_SELECTOR_TAG = 3
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AccessibilityObservables.AppNotificationAppPair>
    let windowObservable: Observable<UIElement?>
    let windowSubject: BehaviorSubject<UIElement?>
    let normalShortcutObservable: Observable<Void>
    
    var compositeDisposable: CompositeDisposable
    var scrollModeDisposable: CompositeDisposable? = CompositeDisposable()
    
    let overlayWindowController: NSWindowController

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
    
    override init() {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        overlayWindowController = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
        
        Utils.registerDefaults()
        
        applicationObservable = AccessibilityObservables.createApplicationObservable().share()
        applicationNotificationObservable = AccessibilityObservables.createApplicationNotificationObservable(applicationObservable: applicationObservable, notifications: AppDelegate.windowEvents + [AXNotification.focusedWindowChanged]).share()
        
        let initialWindowFromApplicationObservable: Observable<UIElement?> = applicationObservable
            .map { appOptional in
                guard let app = appOptional else {
                    return nil
                }
                let windowOptional: UIElement? = {
                    do {
                        return try app.attribute(Attribute.focusedWindow)
                    } catch {
                        return nil
                    }
                }()
                return windowOptional
            }
        
        let windowFromApplicationNotificationObservable: Observable<UIElement?> = applicationNotificationObservable
            .flatMapLatest { pair in
                return Observable.create { observer in
                    guard let notification = pair.notification,
                        let app = pair.app else {
                        observer.onNext(nil)
                        return Disposables.create()
                    }
                    
                    if notification != .focusedWindowChanged {
                        return Disposables.create()
                    }
                    
                    let windowOptional: UIElement? = {
                        do {
                            return try app.attribute(Attribute.focusedWindow)
                        } catch {
                            return nil
                        }
                    }()
                    
                    observer.onNext(windowOptional)
                    return Disposables.create()
                }
            }
        
        windowObservable = Observable.merge([windowFromApplicationNotificationObservable, initialWindowFromApplicationObservable])
        windowSubject = BehaviorSubject(value: nil)

        normalShortcutObservable = Observable.create { observer in
            let tempView = MASShortcutView.init()
            tempView.associatedUserDefaultsKey = Utils.commandShortcutKey
            if tempView.shortcutValue == nil {
                tempView.shortcutValue = Utils.defaultCommandShortcut
            }
            
            MASShortcutBinder.shared()
                .bindShortcut(withDefaultsKey: Utils.commandShortcutKey, toAction: {
                    observer.onNext(Void())
                })
            return Disposables.create()
        }
        
        self.compositeDisposable = CompositeDisposable()
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        SUUpdater.shared()?.delegate = self
        SUUpdater.shared()?.sendsSystemProfile = true
        SUUpdater.shared()?.checkForUpdatesInBackground()
        
        self.compositeDisposable.insert(applicationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { app in
                os_log("Current frontmost application: %@", log: Log.accessibility, String(describing: app))
            })
        )

        self.compositeDisposable.insert(applicationNotificationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { pair in
                if let notification = pair.notification,
                    let app = pair.app {
                    
                    if notification == .focusedWindowChanged {
                        return
                    }

                    self.hideOverlays()
                }
            })
        )
        
        self.compositeDisposable.insert(windowObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                self.hideOverlays()
                os_log("Current window: %@", log: Log.accessibility, String(describing: windowOptional))
                self.windowSubject.onNext(windowOptional)
            })
        )

        let windowNoNilObservable = windowObservable.compactMap { $0 }
        
        self.compositeDisposable.insert(normalShortcutObservable
            .withLatestFrom(windowNoNilObservable, resultSelector: { _, window in
                return window
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { window in
                let isOverlayEmpty = self.overlayWindowController.window?.contentView?.subviews.count == 0
                self.hideOverlays()
                
                if !isOverlayEmpty {
                    return
                }
                
                self.setNormalMode()
            })
        )
    }
    
    func hideOverlays() {
        print("hiding overlays")
        self.overlayWindowController.close()
        self.removeSubviews()
        self.scrollModeDisposable?.dispose()
        self.scrollModeDisposable = CompositeDisposable()
    }
    
    func removeSubviews() {
        self.overlayWindowController.window?.contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }

    func removeHints() {
        self.overlayWindowController.window?.contentView?.subviews.forEach({ view in
            if view is HintView {
                view.removeFromSuperview()
            }
        })
    }
    
    func setNormalMode() {
        self.resizeOverlayWindow()
        let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        textField.stringValue = ""
        textField.placeholderString = "Enter Command"
        textField.isEditable = true
        textField.delegate = self
        textField.overlayTextFieldDelegate = self
        textField.tag = AppDelegate.NORMAL_MODE_TEXT_FIELD_TAG
        
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        textField.wantsLayer = true
        textField.layer?.borderColor = NSColor.gray.cgColor
        textField.layer?.borderWidth = 2
        textField.layer?.cornerRadius = 3
        textField.layer?.backgroundColor = NSColor.white.cgColor
        textField.focusRingType = .none
        // need this otherwise the background color is ignored
        textField.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        textField.drawsBackground = true
        textField.backgroundColor = NSColor.white
        textField.textColor = NSColor.black
        textField.bezelStyle = .roundedBezel
        textField.cell?.usesSingleLineMode = true
        
        textField.sizeToFit()
        textField.setFrameSize(NSSize(width: 530, height: textField.frame.height))

        textField.setFrameOrigin(NSPoint(
            x: (NSScreen.main!.frame.width / 2) - (textField.frame.width / 2),
            y: (NSScreen.main!.frame.height / 2) + (textField.frame.height / 2)
        ))
        
        self.overlayWindowController.window?.contentView?.addSubview(textField)
        self.overlayWindowController.showWindow(nil)
        self.overlayWindowController.window?.makeKeyAndOrderFront(nil)
        textField.becomeFirstResponder()
    }
    
    func resizeOverlayWindow() {
        overlayWindowController.window!.setFrame(NSScreen.main!.frame, display: true, animate: false)
    }
    
    func getCurrentApplicationWindowManually() -> UIElement? {
        guard let nsApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        return {
            do {
                return try Application.init(nsApplication)?.attribute(.focusedWindow)
            } catch {
                return nil
            }
        }()
    }
    
    func setHintSelectorMode(cursorAction: CursorAction, cursorSelector: CursorSelector, elementSelectorArgsOptional: [ElementSelectorArg]?) {
        // if windowSubject does not have the current window, retrieve the current window directly
        // This fixes a bug where opening an application with Vimac causes windowSubject value to be nil
        guard let applicationWindow = (try! self.windowSubject.value()) ?? self.getCurrentApplicationWindowManually(),
            let window = self.overlayWindowController.window else {
            print("Failed to set Hint Selector")
            self.hideOverlays()
            return
        }
        
        self.resizeOverlayWindow()

        let elementsOptional = Utils.traverseUIElementForPressables(rootElement: applicationWindow)
        let menuBarItems = Utils.traverseForMenuBarItems(windowElement: applicationWindow)
        guard let elements = elementsOptional else {
            print("traversal failed")
            self.hideOverlays()
            return
        }
        
        var allElements = elements + menuBarItems
        
        if let elementSelectorArgs = elementSelectorArgsOptional {
            let roles = elementSelectorArgs.flatMap({ Utils.mapArgToRoleString(arg: $0) })
            let rolesString = roles.map({ $0.rawValue })
            let rolesStringSet = Set(rolesString)
            allElements = allElements
                .filter({ element in
                    do {
                        guard let elementRole: String = try element.attribute(.role) else {
                            return false
                        }
                        return rolesStringSet.contains(elementRole)
                    } catch {
                        return false
                    }
                })
        }
        
        let hintStrings = AlphabetHints().hintStrings(linkCount: allElements.count)

        let hintViews: [HintView] = allElements
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
                    let positionRelativeToWindow = window.convertPoint(fromScreen: positionRelativeToScreen)
                    text.associatedButton = button
                    text.frame.origin = positionRelativeToWindow
                    text.zIndex = index
                    return text
                }
                return nil })
            .compactMap({ $0 })
        
        hintViews.forEach { view in
            window.contentView!.addSubview(view)
        }
        
        let selectorTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        selectorTextField.stringValue = ""
        selectorTextField.isEditable = true
        selectorTextField.delegate = self
         selectorTextField.isHidden = true
        selectorTextField.tag = AppDelegate.HINT_SELECTOR_TEXT_FIELD_TAG
        selectorTextField.cursorAction = cursorAction
        selectorTextField.overlayTextFieldDelegate = self
        window.contentView?.addSubview(selectorTextField)
        self.overlayWindowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        selectorTextField.becomeFirstResponder()
    }
    
    func setScrollMode() {
        let selectorTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        selectorTextField.stringValue = ""
        selectorTextField.isEditable = true
        selectorTextField.delegate = self
        selectorTextField.isHidden = true
        selectorTextField.tag = AppDelegate.SCROLL_MODE_SELECTOR_TAG
        selectorTextField.overlayTextFieldDelegate = self
        self.overlayWindowController.window?.contentView?.addSubview(selectorTextField)
        self.overlayWindowController.showWindow(nil)
        self.overlayWindowController.window?.makeKeyAndOrderFront(nil)
        selectorTextField.becomeFirstResponder()
        
        let scrollSensitivity = Int64(UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey))
        
        scrollModeDisposable?.insert(
            AccessibilityObservables.scrollObservable(textField: selectorTextField, character: "j", yAxis: -1 * scrollSensitivity, xAxis: 0, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable?.insert(
            AccessibilityObservables.scrollObservable(textField: selectorTextField, character: "k", yAxis: scrollSensitivity, xAxis: 0, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable?.insert(
            AccessibilityObservables.scrollObservable(textField: selectorTextField, character: "h", yAxis: 0, xAxis: scrollSensitivity, frequencyMilliseconds: 20)
                .subscribe()
        )
        
        scrollModeDisposable?.insert(
            AccessibilityObservables.scrollObservable(textField: selectorTextField, character: "l", yAxis: 0, xAxis: -1 * scrollSensitivity, frequencyMilliseconds: 20)
                .subscribe()
        )
    }
    
    func updateHints(typed: String) {
        guard let window = self.overlayWindowController.window,
            let hintViews = window.contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? else {
            self.hideOverlays()
            return
        }

        hintViews.forEach { hintView in
            hintView.removeFromSuperview()
            if hintView.stringValue.starts(with: typed.uppercased()) {
                let newHintView = HintView(frame: hintView.frame)
                newHintView.initializeHint(hintText: hintView.stringValue, typed: typed.uppercased())
                newHintView.associatedButton = hintView.associatedButton
                window.contentView!.addSubview(newHintView)
            }
        }
    }
    
    // randomly rotate hints
    // ideally we group them into clusters of intersecting hints and rotate within those clusters
    // but this is just a quick fast hack
    func rotateHints() {
        guard let window = self.overlayWindowController.window,
            let hintViews = window.contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]? else {
                self.hideOverlays()
                return
        }
        
        self.removeHints()
        let shuffledHintViews = hintViews.shuffled()
        for (index, hintView) in shuffledHintViews.enumerated() {
            hintView.zIndex = index
            window.contentView?.addSubview(hintView)
        }
    }
    
    func onHintSelectorTextChange(textField: OverlayTextField) {
        let typed = textField.stringValue
        guard let window = self.overlayWindowController.window,
            let hintViews = window.contentView?.subviews.filter ({ $0 is HintView }) as! [HintView]?,
            let action = textField.cursorAction else {
            print("Failed to update hints.")
            self.hideOverlays()
            return
        }
        
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
            print("No matching hints. Exiting Hint Mode")
            self.hideOverlays()
            return
        }
        
        if matchingHints.count == 1 {
            let matchingHint = matchingHints.first!
            let buttonOptional = matchingHint.associatedButton
            guard let button = buttonOptional else {
                print("Couldn't find HintView's associated button. Exiting.")
                self.hideOverlays()
                return
            }
            
            guard let buttonPosition: NSPoint = try! button.attribute(.position),
                let buttonSize: NSSize = try! button.attribute(.size) else {
                return
            }
            
            let centerPositionX = buttonPosition.x + (buttonSize.width / 2)
            let centerPositionY = buttonPosition.y + (buttonSize.height / 2)
            let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)
            print("Matching hint found. Performing command and exiting Hint Mode.")
            self.hideOverlays()
            
            guard let cursorAction = textField.cursorAction else {
                print("Couldn't find text field's associated action")
                return
            }
            
            Utils.moveMouse(position: centerPosition)
            if action == .leftClick {
                Utils.leftClickMouse(position: centerPosition)
            } else if action == .rightClick {
                Utils.rightClickMouse(position: centerPosition)
            } else if action == .doubleLeftClick {
                Utils.doubleLeftClickMouse(position: centerPosition)
            } else if action == .move {
                Utils.moveMouse(position: centerPosition)
            }
            return
        }
        
        // update hints to reflect new typed text
        self.updateHints(typed: typed)
    }
    
    func onInputSubmitted(input: String) {
        self.hideOverlays()
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedInput == "s" {
            self.setScrollMode()
            return
        }
        
        var cursorActionOptional: CursorAction?
        var cursorSelectorOptional: CursorSelector?
        var elementSelectorArgs: [ElementSelectorArg]?
        
        if trimmedInput.starts(with: "ce") {
            cursorActionOptional = .leftClick
            cursorSelectorOptional = .element
            
            let inputSplit = trimmedInput.split(separator: " ")
            if inputSplit.count == 2 {
                let argString = inputSplit.last!
                elementSelectorArgs = argString.split(separator: ";")
                    .map({ ElementSelectorArg(rawValue: String($0)) })
                    .compactMap({ $0 })
            }
        }
        
        else if trimmedInput.starts(with: "rce") {
            cursorActionOptional = .rightClick
            cursorSelectorOptional = .element
            
            let inputSplit = trimmedInput.split(separator: " ")
            if inputSplit.count == 2 {
                let argString = inputSplit.last!
                elementSelectorArgs = argString.split(separator: ";")
                    .map({ ElementSelectorArg(rawValue: String($0)) })
                    .compactMap({ $0 })
            }
        }
        
        else if trimmedInput.starts(with: "dce") {
            cursorActionOptional = .doubleLeftClick
            cursorSelectorOptional = .element
            
            let inputSplit = trimmedInput.split(separator: " ")
            if inputSplit.count == 2 {
                let argString = inputSplit.last!
                elementSelectorArgs = argString.split(separator: ";")
                    .map({ ElementSelectorArg(rawValue: String($0)) })
                    .compactMap({ $0 })
            }
        }
        
        else if trimmedInput.starts(with: "ch") {
            cursorActionOptional = .leftClick
            cursorSelectorOptional = .here
        }
        
        else if trimmedInput.starts(with: "rch") {
            cursorActionOptional = .rightClick
            cursorSelectorOptional = .here
        }
        
        else if trimmedInput.starts(with: "dch") {
            cursorActionOptional = .doubleLeftClick
            cursorSelectorOptional = .here
        }
        
        guard let cursorAction = cursorActionOptional,
            let cursorSelector = cursorSelectorOptional else {
                return
        }
        
        self.setHintSelectorMode(cursorAction: cursorAction, cursorSelector: cursorSelector, elementSelectorArgsOptional: elementSelectorArgs)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.compositeDisposable.dispose()
    }
}

extension AppDelegate : SUUpdaterDelegate {
}

extension AppDelegate : NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if control.tag == AppDelegate.NORMAL_MODE_TEXT_FIELD_TAG {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                self.onInputSubmitted(input: textView.string)
            }
        }
        return false
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField

        switch textField.tag {
        case AppDelegate.HINT_SELECTOR_TEXT_FIELD_TAG:
            self.onHintSelectorTextChange(textField: textField as! OverlayTextField)
        default:
            return
        }
    }
}

extension AppDelegate : OverlayTextFieldDelegate {
    func onEscape() {
        self.hideOverlays()
    }
}
