//
//  ExperimentalPreferenceViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 6/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences

class ExperimentalPreferenceViewController: NSViewController, NSTextFieldDelegate, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.experimental
    let preferencePaneTitle = "Experimental"
    let toolbarItemIcon: NSImage
    
    private var grid: NSGridView!
    private var electronSupportView: NSButton!
    private var nonNativeSupportView: NSButton!
    
    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil)!
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
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false
        
        let electronSupportLabel = NSTextField(labelWithString: "Electron Support:")
        electronSupportView = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onElectronSupportChange))
        electronSupportView.state = UserDefaultsProperties.AXManualAccessibilityEnabled.read() ? .on : .off
        grid.addRow(with: [electronSupportLabel, electronSupportView])
        
        let electronSupportLabelHint = NSTextField(wrappingLabelWithString: "Allow Hint-mode to work on older Electron applications (e.g. Visual Studio Code and Slack)")
        electronSupportLabelHint.font = .labelFont(ofSize: 11)
        electronSupportLabelHint.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, electronSupportLabelHint])
        
        let electronSupportLabelHint2 = NSTextField(wrappingLabelWithString: "Sets the AXManualAccessibility attribute on applications. May lead to slow performance and high CPU usage.")
        electronSupportLabelHint2.font = .labelFont(ofSize: 11)
        electronSupportLabelHint2.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, electronSupportLabelHint2])
        
        let nonNativeSupportLabel = NSTextField(labelWithString: "Emulate VoiceOver:")
        nonNativeSupportView = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onNonNativeSupportChange))
        nonNativeSupportView.state = UserDefaultsProperties.AXEnhancedUserInterfaceEnabled.read() ? .on : .off
        grid.addRow(with: [nonNativeSupportLabel, nonNativeSupportView])
        
        let nonNativeSupportLabelHint = NSTextField(wrappingLabelWithString: "Allow Hint-mode to work on non-native applications such as Firefox.")
        nonNativeSupportLabelHint.font = .labelFont(ofSize: 11)
        nonNativeSupportLabelHint.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, nonNativeSupportLabelHint])
        
        let nonNativeSupportLabelHint2 = NSTextField(wrappingLabelWithString: "Enable this option as a last resort. Emulating VoiceOver has side effects. It breaks window managers and may change the behaviour of your applications.")
        nonNativeSupportLabelHint2.font = .labelFont(ofSize: 11)
        nonNativeSupportLabelHint2.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, nonNativeSupportLabelHint2])
        
        let nonNativeSupportLabelHint3 = NSTextField(wrappingLabelWithString: "Please use a compatible window manager like Rectangle.")
        nonNativeSupportLabelHint3.font = .labelFont(ofSize: 11)
        nonNativeSupportLabelHint3.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, nonNativeSupportLabelHint3])
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            grid.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -200),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    @objc func onElectronSupportChange() {
        let enabled = electronSupportView.state == .on
        UserDefaultsProperties.AXManualAccessibilityEnabled.write(enabled)
    }
    
    @objc func onNonNativeSupportChange() {
        let enabled = nonNativeSupportView.state == .on
        UserDefaultsProperties.AXEnhancedUserInterfaceEnabled.write(enabled)
    }
}
