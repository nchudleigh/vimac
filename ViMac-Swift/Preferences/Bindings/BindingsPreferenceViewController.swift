//
//  BindingsPreferenceViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences

class BindingsPreferenceViewController: NSViewController, PreferencePane, NSTextFieldDelegate {
    let preferencePaneIdentifier = PreferencePane.Identifier.bindings
    let preferencePaneTitle = "Bindings"
    let toolbarItemIcon: NSImage = NSImage(named: NSImage.advancedName)!
    
    private var grid: NSGridView!
    private var hintModeShortcut: MASShortcutView!
    private var scrollModeShortcut: MASShortcutView!

    private var hintModeKeySequenceEnabledCheckbox: NSButton!
    private var hintModeKeySequenceTextField: NSTextField!
    private var scrollModeKeySequenceEnabledCheckbox: NSButton!
    private var scrollModeKeySequenceTextField: NSTextField!
    private var resetDelayTextField: NSTextField!
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        grid = NSGridView(numberOfColumns: 2, rows: 1)
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false
        
        populateGrid()
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }
    
    private func populateGrid() {
        let hintModeShortcutLabel = NSTextField(labelWithString: "Hint Mode Shortcut:")
        hintModeShortcut = MASShortcutView()
        hintModeShortcut.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        grid.addRow(with: [hintModeShortcutLabel, hintModeShortcut])
        
        let scrollModeShortcutLabel = NSTextField(labelWithString: "Scroll Mode Shortcut:")
        scrollModeShortcut = MASShortcutView()
        scrollModeShortcut.associatedUserDefaultsKey = Utils.scrollModeShortcutKey
        grid.addRow(with: [scrollModeShortcutLabel, scrollModeShortcut])
        
        let hintModeKeySequenceLabel = NSTextField(labelWithString: "Hint Mode Key Sequence:")
        hintModeKeySequenceEnabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onHintModeKeySequenceCheckboxClick))
        grid.addRow(with: [hintModeKeySequenceLabel, hintModeKeySequenceEnabledCheckbox])
        
        hintModeKeySequenceTextField = NSTextField()
        hintModeKeySequenceTextField.placeholderString = "fd"
        hintModeKeySequenceTextField.delegate = self
        grid.addRow(with: [NSGridCell.emptyContentView, hintModeKeySequenceTextField])
        
        let scrollModeKeySequenceLabel = NSTextField(labelWithString: "Scroll Mode Key Sequence:")
        scrollModeKeySequenceEnabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onScrollModeKeySequenceCheckboxClick))
        grid.addRow(with: [scrollModeKeySequenceLabel, scrollModeKeySequenceEnabledCheckbox])
        
        scrollModeKeySequenceTextField = NSTextField()
        scrollModeKeySequenceTextField.placeholderString = "jk"
        scrollModeKeySequenceTextField.delegate = self
        grid.addRow(with: [NSGridCell.emptyContentView, scrollModeKeySequenceTextField])
        
        let resetDelayLabel = NSTextField(labelWithString: "Reset Delay (seconds)")
        resetDelayTextField = NSTextField()
        resetDelayTextField.placeholderString = "0.25"
        resetDelayTextField.delegate = self
        grid.addRow(with: [resetDelayLabel, resetDelayTextField])
        
        fillFields()
    }
    
    private func fillFields() {
        let hintModeKeySequenceEnabled = BindingsUserDefaults.keySequenceHintModeEnabled.read()
        hintModeKeySequenceEnabledCheckbox.state = hintModeKeySequenceEnabled ? .on : .off
        hintModeKeySequenceTextField.stringValue = BindingsUserDefaults.keySequenceHintMode.read()
        hintModeKeySequenceTextField.isEnabled = hintModeKeySequenceEnabled

        let scrollModeKeySequenceEnabled = BindingsUserDefaults.keySequenceScrollModeEnabled.read()
        scrollModeKeySequenceEnabledCheckbox.state = scrollModeKeySequenceEnabled ? .on : .off
        scrollModeKeySequenceTextField.stringValue = BindingsUserDefaults.keySequenceScrollMode.read()
        scrollModeKeySequenceTextField.isEnabled = scrollModeKeySequenceEnabled
        
        resetDelayTextField.stringValue = String(BindingsUserDefaults.keySequenceResetDelay.read())
    }
    
    @objc private func onHintModeKeySequenceCheckboxClick() {
        let enabled = hintModeKeySequenceEnabledCheckbox.state == .on
        hintModeKeySequenceTextField.isEnabled = enabled
        
        BindingsUserDefaults.keySequenceHintModeEnabled.write(enabled)
    }
    
    @objc private func onScrollModeKeySequenceCheckboxClick() {
        let enabled = scrollModeKeySequenceEnabledCheckbox.state == .on
        scrollModeKeySequenceTextField.isEnabled = enabled
        
        BindingsUserDefaults.keySequenceScrollModeEnabled.write(enabled)
    }
    
    private func onHintModeKeySequenceTextFieldEndEditing() {
        let value = hintModeKeySequenceTextField.stringValue
        BindingsUserDefaults.keySequenceHintMode.write(value)
    }
    
    private func onScrollModeKeySequenceTextFieldEndEditing() {
        let value = scrollModeKeySequenceTextField.stringValue
        BindingsUserDefaults.keySequenceScrollMode.write(value)
    }
    
    private func onResetDelayTextFieldEndEditing() {
        let valueString = resetDelayTextField.stringValue
        guard let value = Double(valueString) else {
            showInvalidValueDialog(valueString)
            return
        }

        BindingsUserDefaults.keySequenceResetDelay.write(value)
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == hintModeKeySequenceTextField {
            onHintModeKeySequenceTextFieldEndEditing()
            return
        }

        if textField == scrollModeKeySequenceTextField {
            onScrollModeKeySequenceTextFieldEndEditing()
            return
        }
        
        if textField == resetDelayTextField {
            onResetDelayTextFieldEndEditing()
            return
        }
    }
    
    private func showInvalidValueDialog(_ value: String) {
        let alert = NSAlert()
        alert.messageText = "The value \"\(value)\" is invalid."
        alert.informativeText = "Please provide a valid value."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
