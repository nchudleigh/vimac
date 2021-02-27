//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import MASShortcut
import Sparkle
import LaunchAtLogin
import Preferences

@NSApplicationMain
    class AppDelegate: NSObject, NSApplicationDelegate {
    var welcomeWindowController: NSWindowController?
    var permissionPollingTimer: Timer?
    
    private lazy var applicationObservable: Observable<NSRunningApplication?> = createApplicationObservable()
    private lazy var focusedWindowDisturbedObservable: Observable<FrontmostApplicationService.ApplicationNotification> = createFocusedWindowDisturbedObservable()
    private lazy var windowObservable: Observable<Element?> = createFocusedWindowObservable()

    let hintModeShortcutObservable: Observable<Void> = KeyboardShortcuts.shared.hintModeShortcutActivation()
    let scrollModeShortcutObservable: Observable<Void> = KeyboardShortcuts.shared.scrollModeShortcutActivation()
    
    var compositeDisposable: CompositeDisposable
    var scrollModeDisposable: CompositeDisposable? = CompositeDisposable()
    
    let modeCoordinator: ModeCoordinator
    let overlayWindowController: OverlayWindowController
    
    let frontmostAppService = FrontmostApplicationService.init()
    
    override init() {
        
        UIElement.globalMessagingTimeout = 1
        
        InputSourceManager.initialize()
        overlayWindowController = OverlayWindowController()
        modeCoordinator = ModeCoordinator(windowController: overlayWindowController)
        
        Utils.registerDefaults()
        
        LaunchAtLogin.isEnabled = UserDefaults.standard.bool(forKey: Utils.shouldLaunchOnStartupKey)
        
        self.compositeDisposable = CompositeDisposable()
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if self.isAccessibilityPermissionsGranted() {
            self.checkForUpdatesInBackground()
            self.setupWindowEventAndShortcutObservables()
            return
        }
        
        showWelcomeWindowController()
    }
    
    func createApplicationObservable() -> Observable<NSRunningApplication?> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.frontmostAppService.observeFrontmostApp({ app in
                observer.onNext(app)
            })
            return Disposables.create()
        }
    }
    
    func createFocusedWindowDisturbedObservable() -> Observable<FrontmostApplicationService.ApplicationNotification> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.frontmostAppService.observeFocusedWindowDisturbed({ notification in
                observer.onNext(notification)
            })
            return Disposables.create()
        }
    }
    
    func createFocusedWindowObservable() -> Observable<Element?> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }

            self.frontmostAppService.observeFocusedWindow({ window in
                observer.onNext(window)
            })
            return Disposables.create()
        }
    }
    
    func showWelcomeWindowController() {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        welcomeWindowController = storyboard.instantiateController(withIdentifier: "WelcomeWindowController") as? NSWindowController
        NSApp.activate(ignoringOtherApps: true)
        welcomeWindowController?.showWindow(nil)
        welcomeWindowController?.window?.makeKeyAndOrderFront(nil)
        permissionPollingTimer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(closeWelcomeWindowControllerWhenPermissionGranted),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func closeWelcomeWindowControllerWhenPermissionGranted() {
        if self.isAccessibilityPermissionsGranted() {
            permissionPollingTimer?.invalidate()
            permissionPollingTimer = nil
            welcomeWindowController?.close()
            welcomeWindowController = nil
            
            self.checkForUpdatesInBackground()
            self.setupWindowEventAndShortcutObservables()
        }
    }
    
    func setupWindowEventAndShortcutObservables() {
        _ = self.compositeDisposable.insert(applicationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { appOptional in
                if let app = appOptional {
                    Utils.setAccessibilityAttributes(app: app)
                }
            })
        )

        _ = self.compositeDisposable.insert(focusedWindowDisturbedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { notification in
                self.modeCoordinator.exitMode()
            })
        )
        
        _ = self.compositeDisposable.insert(windowObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                self.modeCoordinator.exitMode()
            })
        )

        _ = self.compositeDisposable.insert(hintModeShortcutObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if self?.modeCoordinator.windowController.window?.contentViewController?.className == HintModeViewController.className() {
                    self?.modeCoordinator.exitMode()
                } else {
                    self?.modeCoordinator.setHintMode()
                }
            })
        )
        
        _ = self.compositeDisposable.insert(scrollModeShortcutObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if self?.modeCoordinator.windowController.window?.contentViewController?.className == ScrollModeViewController.className() {
                    self?.modeCoordinator.exitMode()
                } else {
                    self?.modeCoordinator.setScrollMode()
                }
            })
        )
    }
    
    func checkForUpdatesInBackground() {
        SUUpdater.shared()?.delegate = self
        SUUpdater.shared()?.sendsSystemProfile = true
        SUUpdater.shared()?.checkForUpdatesInBackground()
    }
    
    func isAccessibilityPermissionsGranted() -> Bool {
        return UIElement.isProcessTrusted(withPrompt: false)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.compositeDisposable.dispose()
    }
}

extension AppDelegate : SUUpdaterDelegate {
}
