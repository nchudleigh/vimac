import Cocoa
import Preferences

final class HintModePreferenceViewController: NSViewController, NSTextFieldDelegate, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Hint Mode"
    
    private var grid: NSGridView!
    private var customCharactersField: NSTextField!
    private var textSizeField: NSTextField!
    
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
        
        let customCharactersLabel = NSTextField(labelWithString: "Custom Characters:")
        customCharactersField = NSTextField()
        customCharactersField.delegate = self
        customCharactersField.stringValue = UserPreferences.HintMode.CustomCharactersProperty.readUnvalidated() ?? ""
        let customCharactersRow: [NSView] = [customCharactersLabel, customCharactersField]
        grid.addRow(with: customCharactersRow)
        
        let customCharactersHint1 = NSTextField(wrappingLabelWithString: "The characters placed beside UI Elements when hint mode is activated.")
        customCharactersHint1.font = .labelFont(ofSize: 11)
        customCharactersHint1.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, customCharactersHint1])
        
        let customCharactersHint2 = NSTextField(wrappingLabelWithString: "Enter at least 6 unique characters.")
        customCharactersHint2.font = .labelFont(ofSize: 11)
        customCharactersHint2.textColor = .secondaryLabelColor
        grid.addRow(with: [NSGridCell.emptyContentView, customCharactersHint2])
        
        let textSizeLabel = NSTextField(labelWithString: "Text Size:")
        textSizeField = NSTextField()
        textSizeField.delegate = self
        textSizeField.placeholderString = UserPreferences.HintMode.TextSizeProperty.defaultValue
        textSizeField.stringValue = UserPreferences.HintMode.TextSizeProperty.readUnvalidated() ?? ""
        let textSizeRow: [NSView] = [textSizeLabel, textSizeField]
        grid.addRow(with: textSizeRow)
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }
    
    func onCustomCharactersFieldEndEditing() {
        let value = customCharactersField.stringValue
        let isValid = UserPreferences.HintMode.CustomCharactersProperty.isValid(value: value)
        
        if value.count > 0 && !isValid {
            showInvalidValueDialog(value)
        } else {
            UserPreferences.HintMode.CustomCharactersProperty.save(value: value)
        }
    }
    
    func onTextSizeFieldEndEditing() {
        let value = textSizeField.stringValue
        let isValid = UserPreferences.HintMode.TextSizeProperty.isValid(value: value)

        if value.count > 0 && !isValid {
            showInvalidValueDialog(value)
        } else {
            UserPreferences.HintMode.TextSizeProperty.save(value: value)
        }
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == customCharactersField {
            onCustomCharactersFieldEndEditing()
            return
        }

        if textField == textSizeField {
            onTextSizeFieldEndEditing()
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
