//
//  NormalModeViewController.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 9/10/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class NormalModeViewController: ModeViewController, NSTextFieldDelegate {
    let textField = OverlayTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textField.stringValue = ""
        textField.placeholderString = "Enter Command"
        textField.isEditable = true
        textField.delegate = self
        textField.overlayTextFieldDelegate = self
        
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
        
        self.view.addSubview(textField)
    }
    
    func onInputSubmitted(input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedInput == "s" || trimmedInput == "ss" {
            self.modeCoordinator?.setScrollSelectorMode()
            return
        }
        
        if trimmedInput == "sh" {
            self.modeCoordinator?.setScrollMode()
            return
        }
        
        if trimmedInput == "f" {
            self.modeCoordinator?.setFocusMode()
            return
        }
        
        var cursorActionOptional: CursorAction?
        var cursorSelectorOptional: CursorSelector?
        
        if trimmedInput.starts(with: "ce") {
            cursorActionOptional = .leftClick
            cursorSelectorOptional = .element
        }
        else if trimmedInput.starts(with: "rce") {
            cursorActionOptional = .rightClick
            cursorSelectorOptional = .element
        }
        else if trimmedInput.starts(with: "dce") {
            cursorActionOptional = .doubleLeftClick
            cursorSelectorOptional = .element
        }
        else if trimmedInput.starts(with: "me") {
            cursorActionOptional = .move
            cursorSelectorOptional = .element
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
                self.modeCoordinator?.exitMode()
                return
        }
        
        if cursorSelector != .element {
            self.modeCoordinator?.exitMode()
            return
        }
        
        var allowedRoles = [Role]()
        let inputSplit = trimmedInput.split(separator: " ")
        if inputSplit.count > 1 {
            let args = inputSplit.dropFirst(1)
                .flatMap({ $0.split(separator: ";") })
                .map({ String($0) })
            allowedRoles = args
                .map({ ElementSelectorArg(rawValue: String($0)) })
                .compactMap({ $0 })
                .flatMap({ Utils.mapArgRoleToAXRole(arg: $0) })
        }
        
        self.modeCoordinator?.setCursorMode(cursorAction: cursorAction, cursorSelector: cursorSelector, allowedRoles: allowedRoles)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.onInputSubmitted(input: textView.string)
        }
        return false
    }
}
