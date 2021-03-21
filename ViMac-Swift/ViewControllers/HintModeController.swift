import Cocoa
import RxSwift
import os

extension NSEvent {
    static func localEventMonitor(matching: EventTypeMask) -> Observable<NSEvent> {
        Observable.create({ observer in
            let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: matching, handler: { event -> NSEvent? in
                observer.onNext(event)
                // return nil to prevent the event from being dispatched
                // this removes the "doot doot" sound when typing with CMD / CTRL held down
                return nil
            })!

            let cancel = Disposables.create {
                NSEvent.removeMonitor(keyMonitor)
            }
            return cancel
        })
    }
}

// a view controller that has a single view controller child that can be swapped out.
class ContentViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        self.view = NSView()
    }

    func setChildViewController(_ vc: NSViewController) {
        assert(self.children.count <= 1)
        removeChildViewController()

        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
    }

    func removeChildViewController() {
        guard let childVC = self.children.first else { return }
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}

class HintModeUserInterface {
    let frame: NSRect
    let windowController: OverlayWindowController
    let contentViewController: ContentViewController
    var hintsViewController: HintsViewController?

    let textSize = UserPreferences.HintMode.TextSizeProperty.readAsFloat()

    init(frame: NSRect) {
        self.frame = frame
        self.windowController = OverlayWindowController()
        self.contentViewController = ContentViewController()
        self.windowController.window?.contentViewController = self.contentViewController
        self.windowController.fitToFrame(frame)
    }

    func show() {
        self.windowController.showWindow(nil)
        self.windowController.window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        self.contentViewController.view.removeFromSuperview()
        self.windowController.window?.contentViewController = nil
        self.windowController.close()
    }

    func setHints(hints: [Hint]) {
        self.hintsViewController = HintsViewController(hints: hints, textSize: CGFloat(textSize), typed: "")
        self.contentViewController.setChildViewController(self.hintsViewController!)
    }

    func updateInput(input: String) {
        guard let hintsViewController = self.hintsViewController else { return }
        hintsViewController.updateTyped(typed: input)
    }

    func rotateHints() {
        guard let hintsViewController = self.hintsViewController else { return }
        hintsViewController.rotateHints()
    }
}

enum HintModeState {
    case activating
    case activated
    case hintSelected
    case unactivating
}

enum HintModeInputIntent {
    case rotate
    case exit
    case backspace
    case advance(by: String, action: HintAction)
    
    static func from(event: NSEvent) -> HintModeInputIntent? {
        if event.type != .keyDown { return nil }
        if event.keyCode == kVK_Escape { return .exit }
        if event.keyCode == kVK_Delete { return .backspace }
        if event.keyCode == kVK_Space { return .rotate }

        if let characters = event.charactersIgnoringModifiers {
            let action: HintAction = {
                if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue == NSEvent.ModifierFlags.shift.rawValue) {
                    return .rightClick
                } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue == NSEvent.ModifierFlags.command.rawValue) {
                    return .doubleLeftClick
                } else {
                    return .leftClick
                }
            }()
            return .advance(by: characters, action: action)
        }

        return nil
    }
}

class ActiveModeController: ModeControllerDelegate {
    static let shared = ActiveModeController.init()
    
    private var controller: ModeController?
    
    func activateHintMode(app: NSRunningApplication?, window: Element?) {
        deactivate()
        
        controller = HintModeController(app: app, window: window)
        controller?.delegate = self
        controller?.activate()
    }
    
    func activateScrollMode(window: Element) {
        deactivate()
        
        controller = ScrollModeController(window: window)
        controller?.delegate = self
        controller?.activate()
    }
    
    func deactivate() {
        if let controller = controller {
            controller.deactivate()
            self.controller = nil
        }
    }

    // modes can deactivate themselves.
    // this allows self.controller to reflect the current active mode
    func modeDeactivated(controller: ModeController) {
        self.controller = nil
    }
}

protocol ModeController {
    var delegate: ModeControllerDelegate? { get set }
    
    func activate()
    func deactivate()
}

protocol ModeControllerDelegate: AnyObject {
    func modeDeactivated(controller: ModeController)
}

class ScrollModeController: ModeController {
    weak var delegate: ModeControllerDelegate?
    let window: Element
    private var viewController: ScrollModeViewController?
    private var windowController: OverlayWindowController?
    
    init(window: Element) {
        self.window = window
    }
    
    func activate() {
        deactivate()
        
        let focusedWindowFrame = GeometryUtils.convertAXFrameToGlobal(window.frame)
        let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindowFrame)
        
        let wc = OverlayWindowController()
        let vc = ScrollModeViewController.init(window: window)
        
        wc.window?.contentViewController = vc
        wc.fitToFrame(screenFrame)
        wc.showWindow(nil)
        wc.window?.makeKeyAndOrderFront(nil)
        
        self.windowController = wc
        self.viewController = vc
    }
    
    func deactivate() {
        self.viewController?.view.removeFromSuperview()
        self.windowController?.window?.contentViewController = nil
        self.windowController?.close()
        
        self.delegate?.modeDeactivated(controller: self)
    }
    
    private func activeScreenFrame(focusedWindowFrame: NSRect) -> NSRect {
        // When the focused window is in full screen mode in a secondary display,
        // NSScreen.main will point to the primary display.
        // this is a workaround.
        var activeScreen = NSScreen.main!
        var maxArea: CGFloat = 0
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(focusedWindowFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                activeScreen = screen
            }
        }
        return activeScreen.frame
    }
}

class HintModeController: ModeController {
    weak var delegate: ModeControllerDelegate?
    
    let app: NSRunningApplication?
    let window: Element?
    public private(set) var state: HintModeState?

    private let startTime = CFAbsoluteTimeGetCurrent()
    private let disposeBag = DisposeBag()

    let hintCharacters = UserPreferences.HintMode.CustomCharactersProperty.read()
    var ui: HintModeUserInterface!
    
    // available in activated state
    private var hints: [Hint]!
    private var input: String!
    
    init(app: NSRunningApplication?, window: Element?) {
        self.app = app
        self.window = window
    }
    
    func activate() {
        if self.state != nil { return }
        
        onEntryIntoHintMode()
        self.state = .activating
        onEntryIntoActivating()
    }
    
    func deactivate() {
        if self.state == nil { return }
        
        onExitFromHintMode()
        self.delegate?.modeDeactivated(controller: self)
    }
    
    private func onEntryIntoHintMode() {
        let screenFrame: NSRect = {
            if let window = window {
                let focusedWindowFrame: NSRect = GeometryUtils.convertAXFrameToGlobal(window.frame)
                let screenFrame = activeScreenFrame(focusedWindowFrame: focusedWindowFrame)
                return screenFrame
            }
            return NSScreen.main!.frame
        }()

        ui = HintModeUserInterface(frame: screenFrame)
        ui.show()
    }
    
    private func onExitFromHintMode() {
        ui.hide()
    }
    
    private func transitionToActivated(hints: [Hint]) {
        if self.state != .activating { return }
        
        self.hints = hints
        self.input = ""
        self.state = .activated
        onEntryIntoActivated()
    }
    
    private func transitionToDeactivating() {
        if self.state != .activated { return }
        
        self.state = .unactivating
        deactivate()
    }
    
    private func onEntryIntoActivating() {
        queryHints(
            onSuccess: { [weak self] hints in
                self?.transitionToActivated(hints: hints)
            },
            onError: { [weak self] _ in
                self?.transitionToDeactivating()
            })
    }
    
    private func onEntryIntoActivated() {
        ui.setHints(hints: self.hints)
        listenForKeyPress(onEvent: { [weak self] event in
            self?.onKeyPress(event: event)
        })
    }
    
    private func onKeyPress(event: NSEvent) {
        if self.state != .activated { return }
        
        guard let intent = HintModeInputIntent.from(event: event) else { return }
        
        switch intent {
        case .exit:
            transitionToDeactivating()
        case .rotate:
            self.ui.rotateHints()
        case .backspace:
            _ = self.input.popLast()
            ui.updateInput(input: input)
        case .advance(let by, let action):
            self.input = self.input + by
            let hintsWithInputAsPrefix = hints.filter { $0.text.starts(with: input.uppercased()) }

            if hintsWithInputAsPrefix.count == 0 {
                transitionToDeactivating()
                return
            }

            let matchingHint = hintsWithInputAsPrefix.first(where: { $0.text == input.uppercased() })
            
            if let matchingHint = matchingHint {
                transitionToDeactivating()
                performHintAction(matchingHint, action: action)
            }

            ui.updateInput(input: self.input)
        }
    }

    private func queryHints(onSuccess: @escaping ([Hint]) -> Void, onError: @escaping (Error) -> Void) {
        HintModeQueryService.init(app: app, window: window, hintCharacters: hintCharacters).perform()
            .toArray()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { _ in self.logQueryTime() })
            .do(onError: { e in self.logError(e) })
            .subscribe(
                onSuccess: { onSuccess($0) },
                onError: { onError($0) }
            )
            .disposed(by: disposeBag)
    }
    
    private func listenForKeyPress(onEvent: @escaping (NSEvent) -> Void) {
        NSEvent.localEventMonitor(matching: .keyDown)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { event in
                onEvent(event)
            })
            .disposed(by: disposeBag)
    }
    
    private func logQueryTime() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime
        os_log("[Hint mode] query time: %@", log: Log.accessibility, String(describing: timeElapsed))
    }

    private func logError(_ e: Error) {
        os_log("[Hint mode] query error: %@", log: Log.accessibility, String(describing: e))
    }
    
    private func activeScreenFrame(focusedWindowFrame: NSRect) -> NSRect {
        // When the focused window is in full screen mode in a secondary display,
        // NSScreen.main will point to the primary display.
        // this is a workaround.
        var activeScreen = NSScreen.main!
        var maxArea: CGFloat = 0
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(focusedWindowFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                activeScreen = screen
            }
        }
        return activeScreen.frame
    }
    
    private func performHintAction(_ hint: Hint, action: HintAction) {
        let element = hint.element

        let frame = element.clippedFrame ?? element.frame
        let position = frame.origin
        let size = frame.size

        let centerPositionX = position.x + (size.width / 2)
        let centerPositionY = position.y + (size.height / 2)
        let centerPosition = NSPoint(x: centerPositionX, y: centerPositionY)

        Utils.moveMouse(position: centerPosition)

        switch action {
        case .leftClick:
            Utils.leftClickMouse(position: centerPosition)
        case .rightClick:
            Utils.rightClickMouse(position: centerPosition)
        case .doubleLeftClick:
            Utils.doubleLeftClickMouse(position: centerPosition)
        }
    }
}
