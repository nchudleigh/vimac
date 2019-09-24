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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static let NORMAL_MODE_TEXT_FIELD_TAG = 1
    static let HINT_SELECTOR_TEXT_FIELD_TAG = 2
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AccessibilityObservables.AppNotificationAppPair>
    let windowObservable: Observable<UIElement?>
    let windowSubject: BehaviorSubject<UIElement?>

    let normalShortcutObservable: Observable<Void>
    
    var compositeDisposable: CompositeDisposable
    
    let overlayWindowController: NSWindowController

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
    
    override init() {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        overlayWindowController = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
        
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
    
    func setHintSelectorMode(command: Command) {
        guard let applicationWindow = try! self.windowSubject.value(),
            let window = self.overlayWindowController.window else {
            print("Failed to set Hint Selector")
            self.hideOverlays()
            return
        }
        
        self.resizeOverlayWindow()

        let pressableElementsOptional = Utils.traverseUIElementForPressables(rootElement: applicationWindow)
        guard let pressableElements = pressableElementsOptional else {
            print("traversal failed")
            self.hideOverlays()
            return
        }
        
        let hintStrings = AlphabetHints().hintStrings(linkCount: pressableElements.count)

        let hintViews: [HintView] = pressableElements
            .enumerated()
            .map { (index, button) in
                if let positionFlipped: CGPoint = try! button.attribute(.position) {
                    let text = HintView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                    text.initializeHint(hintText: hintStrings[index], typed: "")
                    let positionRelativeToScreen = Utils.toOrigin(point: positionFlipped, size: text.frame.size)
                    let positionRelativeToWindow = window.convertPoint(fromScreen: positionRelativeToScreen)
                    text.associatedButton = button
                    text.frame.origin = positionRelativeToWindow
                    text.zIndex = index
                    return text
                }
                return nil
            }.compactMap({ $0 })
        
        hintViews.forEach { view in
            window.contentView!.addSubview(view)
        }
        
        let selectorTextField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        selectorTextField.stringValue = ""
        selectorTextField.isEditable = true
        selectorTextField.delegate = self
        selectorTextField.isHidden = true
        selectorTextField.tag = AppDelegate.HINT_SELECTOR_TEXT_FIELD_TAG
        selectorTextField.command = command
        selectorTextField.overlayTextFieldDelegate = self
        window.contentView?.addSubview(selectorTextField)
        self.overlayWindowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        selectorTextField.becomeFirstResponder()
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
            let command = textField.command else {
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
            
            guard let command = textField.command else {
                print("Couldn't find text field's associated command")
                return
            }
            
            Utils.moveMouse(position: centerPosition)
            if command == .leftClick {
                Utils.leftClickMouse(position: centerPosition)
            } else if command == .rightClick {
                Utils.rightClickMouse(position: centerPosition)
            } else if command == .doubleLeftClick {
                Utils.doubleLeftClickMouse(position: centerPosition)
            } else if command == .move {
                Utils.moveMouse(position: centerPosition)
            }
            return
        }
        
        // update hints to reflect new typed text
        self.updateHints(typed: typed)
    }
    
    func onInputSubmitted(input: String) {
        self.hideOverlays()
        let commandOptional = parseInput(input: input)
        guard let command = commandOptional else {
            return
        }
        self.setHintSelectorMode(command: command)
    }
    
    func parseInput(input: String) -> Command? {
        let inputTrimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        switch inputTrimmed {
        case "ce":
            return Command.leftClick
        case "dce":
            return Command.doubleLeftClick
        case "rce":
            return Command.rightClick
        case "me":
            return Command.move
        default:
            return nil
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.compositeDisposable.dispose()
    }
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
