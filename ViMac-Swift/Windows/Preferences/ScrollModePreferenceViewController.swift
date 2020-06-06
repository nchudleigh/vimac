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
        
        scrollModeKeysView.stringValue = UserPreferences.ScrollMode.ScrollKeysProperty.readUnvalidated() ?? ""
        
        scrollSensitivityView.integerValue = UserPreferences.ScrollMode.ScrollSensitivityProperty.read()
        
        revHorizontalScrollView.state = UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.read() ? .on : .off
        revVerticalScrollView.state = UserPreferences.ScrollMode.ReverseVerticalScrollProperty.read() ? .on : .off
        
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

    func observeScrollModeKeys() -> Disposable {
        return scrollKeysObservable.bind(onNext: { keys in
            UserPreferences.ScrollMode.ScrollKeysProperty.save(value: keys)
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
        return scrollSensitivityObservable.bind(onNext: { sensitivity in
            let isValid = UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: sensitivity)
            
            if !isValid {
                return
            }
            
            UserPreferences.ScrollMode.ScrollSensitivityProperty.save(value: sensitivity)
        })
    }
    
    func observeRevHorizontalScroll() -> Disposable {
        return revHorizontalScrollObservable.bind(onNext: { isRev in
            UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.save(value: isRev)
        })
    }
    
    func observeRevVerticalScroll() -> Disposable {
        return revVerticalScrollObservable.bind(onNext: { isRev in
            UserPreferences.ScrollMode.ReverseVerticalScrollProperty.save(value: isRev)
        })
    }
}
