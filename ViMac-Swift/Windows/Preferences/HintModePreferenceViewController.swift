import Cocoa
import RxCocoa
import RxSwift
import Preferences

final class HintModePreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Hint Mode"
    
    override var nibName: NSNib.Name? { "HintModePreferenceViewController" }

    @IBOutlet weak var hintModeShortcutView: MASShortcutView!
    @IBOutlet weak var customCharactersView: NSTextField!
    @IBOutlet weak var textSizeView: NSTextField!
    @IBOutlet weak var gridView: NSGridView!
    
    var actionCheckboxes: [NSButton]?
    
    let compositeDisposable = CompositeDisposable()
    
    lazy var customCharactersViewObservable = customCharactersView.rx.text.map({ $0! })
    lazy var customCharactersViewValidityChangeObservable = customCharactersViewObservable.distinctUntilChanged()
    lazy var textSizeObservable = textSizeView.rx.text.map({ $0! })

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hintModeShortcutView.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        
        customCharactersView.stringValue = UserPreferences.HintMode.CustomCharactersProperty.readUnvalidated() ?? ""
        
        textSizeView.stringValue = UserPreferences.HintMode.TextSizeProperty.readUnvalidated() ?? ""
        
        compositeDisposable.insert(observeCustomCharactersChange())
        compositeDisposable.insert(observeCustomCharactersValidityChange())
        compositeDisposable.insert(observeTextSizeChange())
        
        setupActions()
    }

    deinit {
        compositeDisposable.dispose()
    }
    
    func observeCustomCharactersChange() -> Disposable {
        return customCharactersViewObservable.bind(onNext: { [weak self] characters in
            UserPreferences.HintMode.CustomCharactersProperty.save(value: characters)
        })
    }
    
    func observeCustomCharactersValidityChange() -> Disposable {
        return customCharactersViewValidityChangeObservable.bind(onNext: { [weak self] characters in
            let isValid = UserPreferences.HintMode.CustomCharactersProperty.isValid(value: characters)
            
            if !isValid {
                self?.changeCustomTextViewBackgroundColor(textField: self!.customCharactersView, color: NSColor.init(calibratedRed: 132/255, green: 46/255, blue: 48/255, alpha: 1))
                return
            }
            
            self?.changeCustomTextViewBackgroundColor(textField: self!.customCharactersView, color: NSColor.black)
        })
    }
    
    func observeTextSizeChange() -> Disposable {
        return textSizeObservable.bind(onNext: { [weak self] textSize in
            UserPreferences.HintMode.TextSizeProperty.save(value: textSize)

            let isValid = UserPreferences.HintMode.TextSizeProperty.isValid(value: textSize)

            if !isValid {
                self?.changeCustomTextViewBackgroundColor(textField: self!.textSizeView, color: NSColor.init(calibratedRed: 132/255, green: 46/255, blue: 48/255, alpha: 1))
                return
            }
            
            self?.changeCustomTextViewBackgroundColor(textField: self!.textSizeView, color: NSColor.black)
        })
    }
    
    func changeCustomTextViewBackgroundColor(textField: NSTextField, color: NSColor) {
        textField.backgroundColor = color
        
        // setting backgroundColor does not work properly after the first time until text field is out of focus.
        // see: https://stackoverflow.com/a/16489472/10390454
        textField.isEditable = false
        textField.isEditable = true
    }
    
    func setupActions() {
        let label = NSTextField.init(string: "Shown for actions:")
        label.isEditable = false
        label.isSelectable = false
        label.isBezeled = false
        label.drawsBackground = false

        let actions = [
            "AXPress",
            "AXIncrement",
            "AXDecrement",
            "AXConfirm",
            "AXPick",
            "AXCancel",
            "AXRaise",
            "AXShowMenu",
            "AXOpen"
        ]
        
        let whitelistedActions = UserPreferences.HintMode.ActionsProperty.read()

        let actionCheckboxes = actions.map { action -> NSButton in
            let checkbox = NSButton.init(checkboxWithTitle: action, target: nil, action: nil)
            checkbox.state = whitelistedActions.contains(action) ? .on : .off
            return checkbox
        }
        self.actionCheckboxes = actionCheckboxes
        
        gridView.addRow(with: [label, actionCheckboxes.first!])
        for checkbox in actionCheckboxes[1...actionCheckboxes.count-1] {
            gridView.addRow(with: [NSView(), checkbox])
        }
        
        for checkbox in actionCheckboxes {
            let disposable = checkbox.rx.state.bind(onNext: { [weak self] state in
                self?.saveActions()
            })
            compositeDisposable.insert(disposable)
        }
    }
    
    func saveActions() {
        let enabledActions = actionCheckboxes!
            .filter { $0.state == .on }
            .map { $0.title }
        print(enabledActions)
        UserPreferences.HintMode.ActionsProperty.save(value: enabledActions)
    }
}
