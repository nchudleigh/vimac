import Cocoa
import RxCocoa
import RxSwift
import Preferences

final class HintModePreferenceViewController: NSViewController, NSTextFieldDelegate, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Hint Mode"
    
    override var nibName: NSNib.Name? { "HintModePreferenceViewController" }

    @IBOutlet weak var hintModeShortcutView: MASShortcutView!
    @IBOutlet weak var customCharactersView: NSTextField!
    @IBOutlet weak var textSizeView: NSTextField!
    @IBOutlet weak var gridView: NSGridView!
    
    let compositeDisposable = CompositeDisposable()
    
    let customCharactersViewSubject = PublishSubject<String>()
    lazy var customCharactersViewObservable = customCharactersViewSubject.asObserver()
    
    let textSizeSubject = PublishSubject<String>()
    lazy var textSizeObservable = textSizeSubject.asObserver()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hintModeShortcutView.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        
        customCharactersView.stringValue = UserPreferences.HintMode.CustomCharactersProperty.readUnvalidated() ?? ""
        
        textSizeView.stringValue = UserPreferences.HintMode.TextSizeProperty.readUnvalidated() ?? ""
        
        compositeDisposable.insert(observeCustomCharactersChange())
        compositeDisposable.insert(observeTextSizeChange())

        textSizeView.delegate = self
        customCharactersView.delegate = self
    }

    deinit {
        compositeDisposable.dispose()
    }
    
    func observeCustomCharactersChange() -> Disposable {
        return customCharactersViewObservable.bind(onNext: { characters in
            UserPreferences.HintMode.CustomCharactersProperty.save(value: characters)
        })
    }
    
    func observeTextSizeChange() -> Disposable {
        return textSizeObservable.bind(onNext: { textSize in
            UserPreferences.HintMode.TextSizeProperty.save(value: textSize)
        })
    }
}

extension HintModePreferenceViewController {
    
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == customCharactersView {
            customCharactersViewSubject.onNext(textField.stringValue)
        }
        
        if textField == textSizeView {
            textSizeSubject.onNext(textField.stringValue)
        }
    }
}

extension HintModePreferenceViewController {
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == customCharactersView {
            let value = textField.stringValue
            let isValid = UserPreferences.HintMode.CustomCharactersProperty.isValid(value: value)
            
            if value.count > 0 && !isValid {
                showInvalidValueDialog(value)
            }
        }
        
        if textField == textSizeView {
            let value = textField.stringValue
            let isValid = UserPreferences.HintMode.TextSizeProperty.isValid(value: value)
            
            if value.count > 0 && !isValid {
                showInvalidValueDialog(value)
            }
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
