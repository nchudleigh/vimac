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
        
        let electronSupportLabel = NSTextField(labelWithString: "Electron Support (AXManualAccessibility):")
        electronSupportView = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(onElectronSupportChange))
        electronSupportView.state = UserDefaultsProperties.AXManualAccessibilityEnabled.read() ? .on : .off
        grid.addRow(with: [electronSupportLabel, electronSupportView])
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func onElectronSupportChange() {
        let enabled = electronSupportView.state == .on
        UserDefaultsProperties.AXManualAccessibilityEnabled.write(enabled)
    }
}
