import Cocoa
import RxCocoa
import RxSwift
import Preferences

final class ScrollModePreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Scroll Mode"
    
    override var nibName: NSNib.Name? { "ScrollModePreferenceViewController" }
    
    @IBOutlet weak var shortcutView: MASShortcutView!
    @IBOutlet weak var scrollModeKeysView: NSTextField!
    @IBOutlet weak var scrollSensitivityView: NSSlider!
    @IBOutlet weak var revHorizontalScrollView: NSButton!
    @IBOutlet weak var revVerticalScrollView: NSButton!

    let disposeBag = DisposeBag()
    
    lazy var scrollKeysObservable = scrollModeKeysView.rx.text.map({ $0! })
    lazy var scrollKeysValidityObservable = scrollKeysObservable
        .map({ ScrollModePreferenceViewController.isScrollKeysValid(keys: $0) })
        .distinctUntilChanged()
    
    lazy var scrollSensitivityObservable = scrollSensitivityView.rx.value.map({ Int($0) })
    
    lazy var revHorizontalScrollObservable = revHorizontalScrollView.rx.state.map({ $0 == .on })
    lazy var revVerticalScrollObservable = revVerticalScrollView.rx.state.map({ $0 == .on })

    override func viewDidLoad() {
        super.viewDidLoad()
        
        shortcutView.associatedUserDefaultsKey = Utils.scrollModeShortcutKey
        
        scrollModeKeysView.stringValue = readScrollModeKeys()
        
        scrollSensitivityView.integerValue = readScrollSensitivity()
        
        revHorizontalScrollView.state = readSerializedRevHorizontalScroll() ? .on : .off
        revVerticalScrollView.state = readSerializedRevVerticalScroll() ? .on : .off
        
        observeScrollModeKeys().disposed(by: disposeBag)
        observeScrollModeKeysValidity().disposed(by: disposeBag)
        observeScrollSensitivity().disposed(by: disposeBag)
        observeRevHorizontalScroll().disposed(by: disposeBag)
        observeRevVerticalScroll().disposed(by: disposeBag)
    }
    
    static func isScrollKeysValid(keys: String) -> Bool {
        let isCountValid = keys.count == 4 || keys.count == 6
        let areKeysUnique = keys.count == Set(keys).count
        return isCountValid && areKeysUnique
    }
    
    func changeScrollKeysFieldBackgroundColor(color: NSColor) {
        scrollModeKeysView.backgroundColor = color
        scrollModeKeysView.isEditable = false
        scrollModeKeysView.isEditable = true
    }
    
    func readScrollModeKeys() -> String {
        return UserDefaults.standard.string(forKey: Utils.scrollCharacters) ?? ""
    }
    
    func saveScrollModeKeys(scrollKeys: String) {
        UserDefaults.standard.set(scrollKeys, forKey: Utils.scrollCharacters)
    }
    
    func readScrollSensitivity() -> Int {
        return UserDefaults.standard.integer(forKey: Utils.scrollSensitivityKey)
    }
    
    func saveScrollSensitivity(sensitivity: Int) {
        let isValid = sensitivity >= 0 && sensitivity <= 100
        
        if !isValid {
            return
        }
        
        UserDefaults.standard.set(sensitivity, forKey: Utils.scrollSensitivityKey)
    }
    
    func readSerializedRevHorizontalScroll() -> Bool {
        return UserDefaults.standard.bool(forKey: Utils.isHorizontalScrollReversedKey)
    }
    
    func serializeRevHorizontalScroll(isRev: Bool) {
        UserDefaults.standard.set(isRev, forKey: Utils.isHorizontalScrollReversedKey)
    }
    
    func readSerializedRevVerticalScroll() -> Bool {
        return UserDefaults.standard.bool(forKey: Utils.isVerticalScrollReversedKey)
    }
    
    func serializeRevVerticalScroll(isRev: Bool) {
        UserDefaults.standard.set(isRev, forKey: Utils.isVerticalScrollReversedKey)
    }
    
    func observeScrollModeKeys() -> Disposable {
        return scrollKeysObservable.bind(onNext: { [weak self] keys in
            self?.saveScrollModeKeys(scrollKeys: keys)
        })
    }
    
    func observeScrollModeKeysValidity() -> Disposable {
        return scrollKeysValidityObservable.bind(onNext: { [weak self] isValid in
            if !isValid {
                self?.changeScrollKeysFieldBackgroundColor(color: NSColor.init(calibratedRed: 132/255, green: 46/255, blue: 48/255, alpha: 1))
                return
            }
            
            self?.changeScrollKeysFieldBackgroundColor(color: NSColor.black)
        })
    }
    
    func observeScrollSensitivity() -> Disposable {
        return scrollSensitivityObservable.bind(onNext: { [weak self] sensitivity in
            let isValid = sensitivity >= 0 && sensitivity <= 100
            
            if !isValid {
                return
            }
            
            self?.saveScrollSensitivity(sensitivity: sensitivity)
        })
    }
    
    func observeRevHorizontalScroll() -> Disposable {
        return revHorizontalScrollObservable.bind(onNext: { [weak self] isRev in
            self?.serializeRevHorizontalScroll(isRev: isRev)
        })
    }
    
    func observeRevVerticalScroll() -> Disposable {
        return revVerticalScrollObservable.bind(onNext: { [weak self] isRev in
            self?.serializeRevVerticalScroll(isRev: isRev)
        })
    }
}
