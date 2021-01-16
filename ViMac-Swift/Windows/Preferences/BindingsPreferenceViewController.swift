//
//  BindingsPreferenceViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences

class BindingsPreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.bindings
    let preferencePaneTitle = "Bindings"
    
    private var grid: NSGridView!
    private var hintModeShortcut: MASShortcutView!
    private var scrollModeShortcut: MASShortcutView!
    
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
        grid.column(at: 1).width = 250
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
    }
}
