import Cocoa
import RxSwift
import Preferences
import LaunchAtLogin

final class GeneralPreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    let preferencePaneTitle = "General"
    let toolbarItemIcon: NSImage
    
    private var grid: NSGridView!
    private var forceKBLayoutView: NSPopUpButton!
    private var launchAtLoginView: NSButton!
    
    let inputSources = InputSourceManager.inputSources

    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
        } else {
            self.toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!
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
        
        populateGrid()
        
        self.view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func populateGrid() {
        let forceKBLayoutLabel = NSTextField(labelWithString: "Force Keyboard Layout:")
        forceKBLayoutView = createForceKBLayoutView()
        forceKBLayoutView.action = #selector(onForceKBLayoutChange)
        selectActiveForceKBLayout()
        grid.addRow(with: [forceKBLayoutLabel, forceKBLayoutView])
        
        let launchAtLoginLabel = NSTextField(labelWithString: "Startup:")
        launchAtLoginView = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(onLaunchAtLoginChange))
        launchAtLoginView.state = readShouldLaunchAtLogin() ? .on : .off
        grid.addRow(with: [launchAtLoginLabel, launchAtLoginView])
    }
    
    private func createForceKBLayoutView() -> NSPopUpButton {
        let view = NSPopUpButton()
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
            view.menu?.addItem(menu)
        }

        return view
    }
    
    private func selectActiveForceKBLayout() {
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
    
    func readShouldLaunchAtLogin() -> Bool {
        return UserDefaults.standard.bool(forKey: Utils.shouldLaunchOnStartupKey)
    }
    
    func saveShouldLaunchAtLogin(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Utils.shouldLaunchOnStartupKey)
        LaunchAtLogin.isEnabled = enabled
    }

    @objc func onForceKBLayoutChange() {
        let newInputSource = forceKBLayoutView.selectedItem?.representedObject as? InputSource?
        let newInputSourceId = newInputSource??.id
        saveForceKBLayoutId(id: newInputSourceId)
    }
    
    @objc func onLaunchAtLoginChange() {
        let enabled = launchAtLoginView.state == .on
        saveShouldLaunchAtLogin(enabled: enabled)
    }
}
