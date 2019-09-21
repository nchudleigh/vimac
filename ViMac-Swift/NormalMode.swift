//
//  NormalMode.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 20/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxCocoa
import RxSwift

class NormalMode: NSObject, BaseModeProtocol {
    let overlayWindowController: NSWindowController
    var textField: OverlayTextField?
    let applicationWindow: UIElement
    
    weak var delegate: ModeDelegate?
    weak var commandDelegate: NormalModeDelegate?
    
    let NORMAL_MODE_TAG = 1
    
    required init(applicationWindow: UIElement, controller: NSWindowController) {
        self.applicationWindow = applicationWindow
        self.overlayWindowController = controller
        // resize overlay window to same size as application window
        if let windowPosition: CGPoint = try! applicationWindow.attribute(.position),
            let windowSize: CGSize = try! applicationWindow.attribute(.size) {
            let origin = Utils.toOrigin(point: windowPosition, size: windowSize)
            let frame = NSRect(origin: origin, size: windowSize)
            overlayWindowController.window!.setFrame(frame, display: true, animate: false)
        }
    }
    
    func showWindow() {
        self.overlayWindowController.showWindow(nil)
        self.getWindow().makeKeyAndOrderFront(nil)
    }
    
    func getWindow() -> NSWindow {
        return self.overlayWindowController.window!
    }
    
    func activate() {
        self.setNormalMode()
    }
    
    func deactivate() {
        if let d = self.delegate {
            d.onDeactivate()
        }
    }
    
    func removeSubviews() {
        getWindow().contentView?.subviews.forEach({ view in
            view.removeFromSuperview()
        })
    }
    
    func setNormalMode() {
        let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 530, height: 30))
        textField.stringValue = ""
        textField.isEditable = true
        textField.delegate = self
        textField.tag = NORMAL_MODE_TAG
        getWindow().contentView?.addSubview(textField)
        self.overlayWindowController.showWindow(nil)
        getWindow().makeKeyAndOrderFront(nil)
        textField.becomeFirstResponder()
    }
    
    func onEnter(input: String) {
        let commandOptional = parseInput(input: input)
        guard let command = commandOptional else {
            self.commandDelegate?.onInvalidCommand()
            return
        }
        self.commandDelegate?.onCommand(command: command)
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
        case "se":
            return Command.scroll
        default:
            return nil
        }
    }
}

extension NormalMode : NSTextFieldDelegate {
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.onEnter(input: textView.string)
        }
        return false
    }
}

protocol NormalModeDelegate: AnyObject {
    func onCommand(command: Command) -> Void
    func onInvalidCommand() -> Void
}
