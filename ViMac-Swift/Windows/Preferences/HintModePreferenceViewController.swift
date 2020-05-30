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
    lazy var customCharactersViewValidityChangeObservable = customCharactersViewObservable.distinctUntilChanged()

    override func viewDidLoad() {
        super.viewDidLoad()

        customCharactersView.stringValue = readSerializedCustomCharacters()
        
        hintModeShortcutView.associatedUserDefaultsKey = Utils.hintModeShortcutKey
        
        compositeDisposable.insert(observeCustomCharactersChange())
        compositeDisposable.insert(observeCustomCharactersValidityChange())
    }

    deinit {
        compositeDisposable.dispose()
    }
    
    func readSerializedCustomCharacters() -> String {
        return UserDefaults.standard.string(forKey: Utils.hintCharacters) ?? ""
    }
    
    func observeCustomCharactersChange() -> Disposable {
        return customCharactersViewObservable.bind(onNext: { [weak self] characters in
            self?.serializeCustomCharacters(characters: characters)
        })
    }
    
    func observeCustomCharactersValidityChange() -> Disposable {
        return customCharactersViewValidityChangeObservable.bind(onNext: { [weak self] characters in
            let isValid = self!.isCustomCharactersValid(characters: characters)
            
            if !isValid {
                self?.changeCustomTextViewBackgroundColor(color: NSColor.init(calibratedRed: 132/255, green: 46/255, blue: 48/255, alpha: 1))
                return
            }
            
            self?.changeCustomTextViewBackgroundColor(color: NSColor.black)
        })
    }
    
    func changeCustomTextViewBackgroundColor(color: NSColor) {
        customCharactersView.backgroundColor = color
        
        // setting backgroundColor does not work properly after the first time until text field is out of focus.
        // see: https://stackoverflow.com/a/16489472/10390454
        customCharactersView.isEditable = false
        customCharactersView.isEditable = true
    }

    func isCustomCharactersValid(characters: String) -> Bool {
        let minAllowedCharacters = 10
        let isEqOrMoreThanMinChars = characters.count >= minAllowedCharacters
        let areCharsUnique = characters.count == Set(characters).count
        return isEqOrMoreThanMinChars && areCharsUnique
    }
    
    func serializeCustomCharacters(characters: String) {
        print("serializing characters " + characters)
        UserDefaults.standard.set(characters, forKey: Utils.hintCharacters)
    }
}
