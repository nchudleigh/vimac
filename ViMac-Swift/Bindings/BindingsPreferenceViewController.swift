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
    let preferencePaneIdentifier = Preferences.PaneIdentifier.bindings
    let preferencePaneTitle = "Bindings"
    let toolbarItemIcon: NSImage
    
    private var grid: NSGridView!
    private var hintModeShortcut: MASShortcutView!
    private var scrollModeShortcut: MASShortcutView!

    private var holdSpaceToActivateHintModeCheckbox: NSButton!
    private var hintModeKeySequenceEnabledCheckbox: NSButton!
    private var hintModeKeySequenceTextField: NSTextField!
    private var scrollModeKeySequenceEnabledCheckbox: NSButton!
    private var scrollModeKeySequenceTextField: NSTextField!
    private var resetDelayTextField: NSTextField!
    
    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)!
        } else {
            self.toolbarItemIcon = NSImage(named: NSImage.advancedName)!
        }
        
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
        grid.column(at: 0).xPlacement = .leading
        grid.translatesAutoresizingMaskIntoConstraints = false
        
        populateGrid()
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            grid.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -200),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func populateGrid() {
        let holdSpaceToActivateHintModeLabel = NSTextField(labelWithString: "Hold Space to activate Hint-mode:")
        holdSpaceToActivateHintModeCheckbox = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onHoldSpaceToActivateHintModeCheckboxClick))
        grid.addRow(with: [holdSpaceToActivateHintModeLabel, holdSpaceToActivateHintModeCheckbox])
        
        grid.addRow(with: [])
        grid.addRow(with: [])
        
        let shortcutActivationLabel = NSTextField(labelWithString: "Shortcut Activation")
        shortcutActivationLabel.font = .boldSystemFont(ofSize: 13)
        grid.addRow(with: [shortcutActivationLabel])
        
        let hintModeShortcutLabel = NSTextField(labelWithString: "Hint Mode Shortcut:")
        hintModeShortcut = MASShortcutView()
        hintModeShortcut.associatedUserDefaultsKey = KeyboardShortcuts.shared.hintModeShortcutKey
        grid.addRow(with: [hintModeShortcutLabel, hintModeShortcut])
        
        let scrollModeShortcutLabel = NSTextField(labelWithString: "Scroll Mode Shortcut:")
        scrollModeShortcut = MASShortcutView()
        scrollModeShortcut.associatedUserDefaultsKey = KeyboardShortcuts.shared.scrollModeShortcutKey
        grid.addRow(with: [scrollModeShortcutLabel, scrollModeShortcut])
        
        grid.addRow(with: [])
        grid.addRow(with: [])
        
        let keySequenceHeaderLabel = NSTextField(labelWithString: "Key Sequence Activation")
        keySequenceHeaderLabel.font = .boldSystemFont(ofSize: 13)
        grid.addRow(with: [keySequenceHeaderLabel])
        
        let keySequenceHeaderHint1 = NSTextField(wrappingLabelWithString: "Activate Vimac by typing key-sequences")
        keySequenceHeaderHint1.font = .labelFont(ofSize: 13)
        keySequenceHeaderHint1.textColor = .secondaryLabelColor
        grid.addRow(with: [keySequenceHeaderHint1])
        spanCellHorizontally(
            cell: grid.cell(for: keySequenceHeaderHint1)!,
            length: 2
        )
        
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
    
    private func spanCellHorizontally(cell: NSGridCell, length: Int) {
        let row = grid.index(of: cell.row!)
        grid.mergeCells(
            inHorizontalRange: .init(location: 0, length: length),
            verticalRange: .init(location: row, length: 1)
        )
    }
    
    private func fillFields() {
        holdSpaceToActivateHintModeCheckbox.state = UserDefaultsProperties.holdSpaceHintModeActivationEnabled.read() ? .on : .off
        
        let hintModeKeySequenceEnabled = UserDefaultsProperties.keySequenceHintModeEnabled.read()
        hintModeKeySequenceEnabledCheckbox.state = hintModeKeySequenceEnabled ? .on : .off
        hintModeKeySequenceTextField.stringValue = UserDefaultsProperties.keySequenceHintMode.read()
        hintModeKeySequenceTextField.isEnabled = hintModeKeySequenceEnabled

        let scrollModeKeySequenceEnabled = UserDefaultsProperties.keySequenceScrollModeEnabled.read()
        scrollModeKeySequenceEnabledCheckbox.state = scrollModeKeySequenceEnabled ? .on : .off
        scrollModeKeySequenceTextField.stringValue = UserDefaultsProperties.keySequenceScrollMode.read()
        scrollModeKeySequenceTextField.isEnabled = scrollModeKeySequenceEnabled
        
        resetDelayTextField.stringValue = String(UserDefaultsProperties.keySequenceResetDelay.read())
    }
    
    @objc private func onHoldSpaceToActivateHintModeCheckboxClick() {
        let enabled = holdSpaceToActivateHintModeCheckbox.state == .on
        UserDefaultsProperties.holdSpaceHintModeActivationEnabled.write(enabled)
    }
    
    @objc private func onHintModeKeySequenceCheckboxClick() {
        let enabled = hintModeKeySequenceEnabledCheckbox.state == .on
        hintModeKeySequenceTextField.isEnabled = enabled
        
        UserDefaultsProperties.keySequenceHintModeEnabled.write(enabled)
    }
    
    @objc private func onScrollModeKeySequenceCheckboxClick() {
        let enabled = scrollModeKeySequenceEnabledCheckbox.state == .on
        scrollModeKeySequenceTextField.isEnabled = enabled
        
        UserDefaultsProperties.keySequenceScrollModeEnabled.write(enabled)
    }
    
    private func onHintModeKeySequenceTextFieldChange() {
        let value = hintModeKeySequenceTextField.stringValue
        UserDefaultsProperties.keySequenceHintMode.write(value)
    }
    
    private func onScrollModeKeySequenceTextFieldChange() {
        let value = scrollModeKeySequenceTextField.stringValue
        UserDefaultsProperties.keySequenceScrollMode.write(value)
    }
    
    private func onResetDelayTextFieldChange() {
        let valueString = resetDelayTextField.stringValue
        UserDefaultsProperties.keySequenceResetDelay.write(valueString)
    }
    
    private func onResetDelayTextFieldEndEditing() {
        let valueString = resetDelayTextField.stringValue
        if valueString.count > 0 && Double(valueString) == nil {
            showInvalidValueDialog(valueString)
            return
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == hintModeKeySequenceTextField {
            onHintModeKeySequenceTextFieldChange()
            return
        }

        if textField == scrollModeKeySequenceTextField {
            onScrollModeKeySequenceTextFieldChange()
            return
        }
        
        if textField == resetDelayTextField {
            onResetDelayTextFieldChange()
            return
        }
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
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
