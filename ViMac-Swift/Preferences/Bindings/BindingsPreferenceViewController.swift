//
//  BindingsPreferenceViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences
import RxSwift

class BindingsPreferenceViewController: NSViewController, PreferencePane {
    enum Event {
        case hintModeKeySequenceEnabled(enabled: Bool)
        case hintModeKeySequenceUpdate(sequence: String)
        case scrollModeKeySequenceEnabled(enabled: Bool)
        case scrollModeKeySequenceUpdate(sequence: String)
    }
    
    enum Action {
        case writeConfig(config: BindingsConfig)
    }
    
    let preferencePaneIdentifier = PreferencePane.Identifier.bindings
    let preferencePaneTitle = "Bindings"
    let toolbarItemIcon: NSImage = NSImage(named: NSImage.advancedName)!
    
    private let disposeBag = DisposeBag()
    
    private var grid: NSGridView!
    private var hintModeShortcut: MASShortcutView!
    private var scrollModeShortcut: MASShortcutView!

    private var hintModeKeySequenceEnabledCheckbox: NSButton!
    private var hintModeKeySequenceTextField: NSTextField!
    private var scrollModeKeySequenceEnabledCheckbox: NSButton!
    private var scrollModeKeySequenceTextField: NSTextField!
    
    private let bindingsRepo: BindingsRepository = BindingsRepository()
    private lazy var bindingsConfig = bindingsRepo.readLive().share().asDriver(onErrorRecover: { _ in fatalError() })
    
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
        
        bind()
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
        hintModeKeySequenceEnabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
        grid.addRow(with: [hintModeKeySequenceLabel, hintModeKeySequenceEnabledCheckbox])
        
        hintModeKeySequenceTextField = NSTextField()
        hintModeKeySequenceTextField.placeholderString = "fd"
        grid.addRow(with: [NSGridCell.emptyContentView, hintModeKeySequenceTextField])
        
        let scrollModeKeySequenceLabel = NSTextField(labelWithString: "Scroll Mode Key Sequence:")
        scrollModeKeySequenceEnabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
        grid.addRow(with: [scrollModeKeySequenceLabel, scrollModeKeySequenceEnabledCheckbox])
        
        scrollModeKeySequenceTextField = NSTextField()
        scrollModeKeySequenceTextField.placeholderString = "fd"
        grid.addRow(with: [NSGridCell.emptyContentView, scrollModeKeySequenceTextField])
    }
    
    private func bind() {
        bindingsConfig
            .map { $0.hintModeKeySequenceEnabled }
            .map({ $0 ? NSControl.StateValue.on : NSControl.StateValue.off })
            .drive(hintModeKeySequenceEnabledCheckbox.rx.state)
            .disposed(by: disposeBag)
        
        bindingsConfig
            .map { $0.hintModeKeySequence }
            .drive(hintModeKeySequenceTextField.rx.text)
            .disposed(by: disposeBag)
        
        bindingsConfig
            .map { $0.hintModeKeySequenceEnabled }
            .drive(hintModeKeySequenceTextField.rx.isEnabled)
            .disposed(by: disposeBag)
        
        bindingsConfig
            .map { $0.scrollModeKeySequenceEnabled }
            .map({ $0 ? NSControl.StateValue.on : NSControl.StateValue.off })
            .drive(scrollModeKeySequenceEnabledCheckbox.rx.state)
            .disposed(by: disposeBag)
        
        bindingsConfig
            .map { $0.scrollModeKeySequence }
            .drive(scrollModeKeySequenceTextField.rx.text)
            .disposed(by: disposeBag)
        
        bindingsConfig
            .map { $0.scrollModeKeySequenceEnabled }
            .drive(scrollModeKeySequenceTextField.rx.isEnabled)
            .disposed(by: disposeBag)
        
        actions(events: events())
            .bind(onNext: { action in
                switch action {
                case .writeConfig(let config):
                    self.bindingsRepo.write(config)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func events() -> Observable<Event> {
        let hintModeKeySequenceEnabled = hintModeKeySequenceEnabledCheckbox.rx.state.map({ $0 == .on }).map({ Event.hintModeKeySequenceEnabled(enabled: $0) })
        let hintModeKeySequenceChange = hintModeKeySequenceTextField.rx.text.map { Event.hintModeKeySequenceUpdate(sequence: $0 ?? "") }
        return Observable.merge(hintModeKeySequenceEnabled, hintModeKeySequenceChange)
    }
    
    private func actions(events: Observable<Event>) -> Observable<Action> {
        return events
            .withLatestFrom(bindingsConfig) { ($0, $1) }
            .map { arg in
                let (event, config) = arg
                switch event {
                case .hintModeKeySequenceEnabled(let enabled):
                    let config = BindingsConfig(
                        hintModeKeySequenceEnabled: enabled,
                        hintModeKeySequence: config.hintModeKeySequence,
                        scrollModeKeySequenceEnabled: config.scrollModeKeySequenceEnabled,
                        scrollModeKeySequence: config.scrollModeKeySequence,
                        resetDelay: config.resetDelay
                    )
                    return Action.writeConfig(config: config)
                case .hintModeKeySequenceUpdate(let sequence):
                    let config = BindingsConfig(
                        hintModeKeySequenceEnabled: config.hintModeKeySequenceEnabled,
                        hintModeKeySequence: sequence,
                        scrollModeKeySequenceEnabled: config.scrollModeKeySequenceEnabled,
                        scrollModeKeySequence: config.scrollModeKeySequence,
                        resetDelay: config.resetDelay
                    )
                    return Action.writeConfig(config: config)
                case .scrollModeKeySequenceEnabled(let enabled):
                        let config = BindingsConfig(
                            hintModeKeySequenceEnabled: config.hintModeKeySequenceEnabled,
                            hintModeKeySequence: config.hintModeKeySequence,
                            scrollModeKeySequenceEnabled: config.scrollModeKeySequenceEnabled,
                            scrollModeKeySequence: config.scrollModeKeySequence,
                            resetDelay: config.resetDelay
                        )
                        return Action.writeConfig(config: config)
                    case .scrollModeKeySequenceUpdate(let sequence):
                        let config = BindingsConfig(
                            hintModeKeySequenceEnabled: config.hintModeKeySequenceEnabled,
                            hintModeKeySequence: sequence,
                            scrollModeKeySequenceEnabled: config.scrollModeKeySequenceEnabled,
                            scrollModeKeySequence: config.scrollModeKeySequence,
                            resetDelay: config.resetDelay
                        )
                        return Action.writeConfig(config: config)
                }
            }
    }
}
