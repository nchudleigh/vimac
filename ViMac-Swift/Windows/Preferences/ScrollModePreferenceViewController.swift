import Cocoa
import RxCocoa
import RxSwift
import Preferences

final class ScrollModePreferenceViewController: NSViewController, NSTextFieldDelegate, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Scroll Mode"
    
    override var nibName: NSNib.Name? { "ScrollModePreferenceViewController" }
    
    @IBOutlet weak var shortcutView: MASShortcutView!
    @IBOutlet weak var scrollModeKeysView: NSTextField!
    @IBOutlet weak var scrollSensitivityView: NSSlider!
    @IBOutlet weak var revHorizontalScrollView: NSButton!
    @IBOutlet weak var revVerticalScrollView: NSButton!

    let disposeBag = DisposeBag()
    
    let scrollKeysSubject = PublishSubject<String>()
    lazy var scrollKeysObservable = scrollKeysSubject.asObserver()
    
    lazy var scrollSensitivityObservable = scrollSensitivityView.rx.value.map({ Int($0) })
    
    lazy var revHorizontalScrollObservable = revHorizontalScrollView.rx.state.map({ $0 == .on })
    lazy var revVerticalScrollObservable = revVerticalScrollView.rx.state.map({ $0 == .on })

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollModeKeysView.delegate = self
        
        shortcutView.associatedUserDefaultsKey = Utils.scrollModeShortcutKey
        
        scrollModeKeysView.stringValue = UserPreferences.ScrollMode.ScrollKeysProperty.readUnvalidated() ?? ""
        
        scrollSensitivityView.integerValue = UserPreferences.ScrollMode.ScrollSensitivityProperty.read()
        
        revHorizontalScrollView.state = UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.read() ? .on : .off
        revVerticalScrollView.state = UserPreferences.ScrollMode.ReverseVerticalScrollProperty.read() ? .on : .off
        
        observeScrollModeKeys().disposed(by: disposeBag)
        observeScrollSensitivity().disposed(by: disposeBag)
        observeRevHorizontalScroll().disposed(by: disposeBag)
        observeRevVerticalScroll().disposed(by: disposeBag)
    }
    
    func isScrollKeysValid(keys: String) -> Bool {
        let isCountValid = keys.count == 4 || keys.count == 6
        let areKeysUnique = keys.count == Set(keys).count
        return isCountValid && areKeysUnique
    }

    func observeScrollModeKeys() -> Disposable {
        return scrollKeysObservable.bind(onNext: { keys in
            UserPreferences.ScrollMode.ScrollKeysProperty.save(value: keys)
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

extension ScrollModePreferenceViewController {
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == scrollModeKeysView {
            scrollKeysSubject.onNext(textField.stringValue)
        }
    }
}

extension ScrollModePreferenceViewController {
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == scrollModeKeysView {
            let value = textField.stringValue
            let isValid = isScrollKeysValid(keys: value)
            
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
