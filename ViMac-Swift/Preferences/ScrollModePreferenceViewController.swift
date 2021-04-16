import Cocoa
import Preferences

final class ScrollModePreferenceViewController: NSViewController, NSTextFieldDelegate, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.scrollMode
    let preferencePaneTitle = "Scroll Mode"
    let toolbarItemIcon: NSImage
    
    private var grid: NSGridView!
    private var scrollKeysField: NSTextField!
    private var scrollSensitivityView: NSSlider!
    private var revHorizontalScrollView: NSButton!
    private var revVerticalScrollView: NSButton!
    
    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "dpad", accessibilityDescription: nil)!
        } else {
            self.toolbarItemIcon = NSImage(named: "NSColorPanel")!
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
        
        let scrollKeysLabel = NSTextField(labelWithString: "Scroll Keys:")
        scrollKeysField = NSTextField()
        scrollKeysField.delegate = self
        scrollKeysField.placeholderString = UserPreferences.ScrollMode.ScrollKeysProperty.defaultValue
        scrollKeysField.stringValue = UserPreferences.ScrollMode.ScrollKeysProperty.readUnvalidated() ?? ""
        let scrollKeysRow: [NSView] = [scrollKeysLabel, scrollKeysField]
        grid.addRow(with: scrollKeysRow)
        
        let scrollKeysHint1 = NSTextField(wrappingLabelWithString: "Format: {left},{down},{up},{right},{half-down},{half-up},{bottom},{top}")
        scrollKeysHint1.font = .labelFont(ofSize: 11)
        scrollKeysHint1.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, scrollKeysHint1])
        
        let scrollSensitivityLabel = NSTextField(labelWithString: "Scroll Sensitivity:")
        scrollSensitivityView = NSSlider()
        scrollSensitivityView.minValue = 0
        scrollSensitivityView.maxValue = 100
        scrollSensitivityView.numberOfTickMarks = 10
        scrollSensitivityView.integerValue = UserPreferences.ScrollMode.ScrollSensitivityProperty.read()
        scrollSensitivityView.target = self
        scrollSensitivityView.action = #selector(onScrollSensitivityFieldEdit)
        grid.addRow(with: [scrollSensitivityLabel, scrollSensitivityView])
        
        let reverseScrollLabel = NSTextField(labelWithString: "Reverse Scroll:")
        revHorizontalScrollView = NSButton(checkboxWithTitle: "Horizontal", target: self, action: #selector(onRevHorizontalScrollEdit))
        revHorizontalScrollView.state = UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.read() ? .on : .off
        grid.addRow(with: [reverseScrollLabel, revHorizontalScrollView])

        revVerticalScrollView = NSButton(checkboxWithTitle: "Vertical", target: self, action: #selector(onRevVerticalScrollEdit))
        revVerticalScrollView.state = UserPreferences.ScrollMode.ReverseVerticalScrollProperty.read() ? .on : .off
        grid.addRow(with: [NSGridCell.emptyContentView, revVerticalScrollView])
        

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
    
    func isScrollKeysValid(keys: String) -> Bool {
        return UserPreferences.ScrollMode.ScrollKeysProperty.isValid(value: keys)
    }
    
    func onScrollKeysFieldChange() {
        let value = scrollKeysField.stringValue
        UserPreferences.ScrollMode.ScrollKeysProperty.save(value: value)
    }

    func onScrollKeysFieldEndEditing() {
        let value = scrollKeysField.stringValue
        let isValid = isScrollKeysValid(keys: value)
        
        if value.count > 0 && !isValid {
            showInvalidValueDialog(value)
        }
    }
    
    @objc func onScrollSensitivityFieldEdit() {
        let value = scrollSensitivityView.integerValue
        let isValid = UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: value)
        
        if !isValid {
            return
        }
        UserPreferences.ScrollMode.ScrollSensitivityProperty.save(value: value)
    }
    
    @objc func onRevHorizontalScrollEdit() {
        let value = revHorizontalScrollView.state == .on
        UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.save(value: value)
    }

    @objc func onRevVerticalScrollEdit() {
        let value = revVerticalScrollView.state == .on
        UserPreferences.ScrollMode.ReverseVerticalScrollProperty.save(value: value)
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == scrollKeysField {
            onScrollKeysFieldChange()
            return
        }
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == scrollKeysField {
            onScrollKeysFieldEndEditing()
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
