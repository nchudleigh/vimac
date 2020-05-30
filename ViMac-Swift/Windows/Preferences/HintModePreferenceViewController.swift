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
    
    let compositeDisposable = CompositeDisposable()
    
    lazy var customCharactersViewObservable = customCharactersView.rx.text.map({ $0! })

    lazy var customCharactersViewValidityChangeObservable = customCharactersViewObservable.distinctUntilChanged({ [weak self] (a, b) in
        let bIsValid = self!.isCustomCharactersValid(characters: b)
        
        if bIsValid {
            return false
        }
        
        let aIsValid = self!.isCustomCharactersValid(characters: a)
        
        return aIsValid == bIsValid
    })

    override func viewDidLoad() {
        super.viewDidLoad()

        customCharactersView.stringValue = readSerializedCustomCharacters()
        
        hintModeShortcutView.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        
        compositeDisposable.insert(observeCustomCharacters())
    }

    deinit {
        compositeDisposable.dispose()
    }
    
    func readSerializedCustomCharacters() -> String {
        return UserDefaults.standard.string(forKey: Utils.hintCharacters) ?? ""
    }
    
    
    func observeCustomCharacters() -> Disposable {
        return customCharactersViewValidityChangeObservable.bind(onNext: { [weak self] characters in
            self?.onCustomCharactersChange(characters: characters)
        })
    }
    
    func changeCustomTextViewBackgroundColor(color: NSColor) {
        customCharactersView.backgroundColor = color
        
        // setting backgroundColor does not work properly after the first time until text field is out of focus.
        // see: https://stackoverflow.com/a/16489472/10390454
        customCharactersView.isEditable = false
        customCharactersView.isEditable = true
    }
    
    func onCustomCharactersChange(characters: String) {
        let isValidInput = isCustomCharactersValid(characters: characters)
        
        if !isValidInput {
            changeCustomTextViewBackgroundColor(color: NSColor.init(calibratedRed: 132/255, green: 46/255, blue: 48/255, alpha: 1))
            serializeCustomCharacters(characters: AlphabetHints.defaultHintCharacters)
            return
        }
        
        changeCustomTextViewBackgroundColor(color: NSColor.black)
        serializeCustomCharacters(characters: characters)
    }

    func isCustomCharactersValid(characters: String) -> Bool {
        let minAllowedCharacters = 10
        let isEqOrMoreThanMinChars = characters.count >= minAllowedCharacters
        let areCharsUnique = characters.count == Set(characters).count
        return isEqOrMoreThanMinChars && areCharsUnique
    }
    
    func serializeCustomCharacters(characters: String) {
        UserDefaults.standard.set(characters, forKey: Utils.hintCharacters)
    }
}
