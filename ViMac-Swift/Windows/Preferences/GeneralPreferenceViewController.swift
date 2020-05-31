import Cocoa
import RxSwift
import Preferences
import LaunchAtLogin

final class GeneralPreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.general
    let preferencePaneTitle = "General"

    override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }

    @IBOutlet weak var forceKBLayoutView: NSPopUpButton!
    @IBOutlet weak var launchAtLoginView: NSButton!
    
    let inputSources = InputSourceManager.inputSources
    
    let disposeBag = DisposeBag()
    
    lazy var launchAtLoginObservable = launchAtLoginView.rx.state.map({ $0 == .on })

    override func viewDidLoad() {
        super.viewDidLoad()

        setupForceKeyboardLayoutMenu()
        
        launchAtLoginView.state = readShouldLaunchAtLogin() ? .on : .off
        
        observeLaunchAtLogin().disposed(by: disposeBag)
    }
    
    func setupForceKeyboardLayoutMenu() {
        // represents disabled
        let emptyMenuItem = NSMenuItem.init()
        emptyMenuItem.title = ""
        
        let menuItems = inputSources.map({ source -> NSMenuItem in
            let menuItem = NSMenuItem.init()
            menuItem.title = source.name
            menuItem.representedObject = source
            return menuItem
        })
        
        for menu in [emptyMenuItem] + menuItems {
            forceKBLayoutView.menu?.addItem(menu)
        }
        
        selectActiveForceKBLayout()
    }
    
    func selectActiveForceKBLayout() {
        let currentForcedKeyboardLayoutId = readForceKeyboardLayoutId()
        
        if currentForcedKeyboardLayoutId == nil {
            forceKBLayoutView.selectItem(at: 0)
            return
        }

        // add one to offset the empty menu item
        let iMaybe = inputSources.firstIndex(where: { $0.id == currentForcedKeyboardLayoutId }).map({ $0 + 1 })
        
        guard let i = iMaybe else {
            forceKBLayoutView.selectItem(at: 0)
            return
        }
        
        forceKBLayoutView.selectItem(at: i)
    }
    
    func readShouldLaunchAtLogin() -> Bool {
        return UserDefaults.standard.bool(forKey: Utils.shouldLaunchOnStartupKey)
    }
    
    func saveShouldLaunchAtLogin(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Utils.shouldLaunchOnStartupKey)
        
        LaunchAtLogin.isEnabled = enabled
    }
    
    func readForceKeyboardLayoutId() -> String? {
        let rMaybe = UserDefaults.standard.string(forKey: Utils.forceKeyboardLayoutKey)
        
        guard let r = rMaybe else {
            return nil
        }
        
        if r.count == 0 {
            return nil
        }
        
        return r
    }
    
    func saveForceKBLayoutId(id: String?) {
        UserDefaults.standard.set(id, forKey: Utils.forceKeyboardLayoutKey)
    }

    @IBAction func onForceKBLayoutChange(_ sender: Any) {
        let newInputSource = forceKBLayoutView.selectedItem?.representedObject as? InputSource?
        let newInputSourceId = newInputSource??.id
        saveForceKBLayoutId(id: newInputSourceId)
    }
    
    func observeLaunchAtLogin() -> Disposable {
        return launchAtLoginObservable.bind(onNext: { [weak self] enabled in
            self?.saveShouldLaunchAtLogin(enabled: enabled)
        })
    }
}
