//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import MASShortcut
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let hintShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .option, .control])
    static let scrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_C, modifierFlags: [.command, .option, .control])
    
    let storyboard: NSStoryboard
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AccessibilityObservables.AppNotificationAppPair>
    let windowObservable: Observable<UIElement?>
    
    var scrollMode: ScrollMode?
    var hintMode: HintMode?
    
    let hintShortcutObservable: Observable<Void>
    let scrollShortcutObservable: Observable<Void>

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
    
    override init() {
        storyboard =
            NSStoryboard.init(name: "Main", bundle: nil)
        applicationObservable = AccessibilityObservables.createApplicationObservable().share()
        applicationNotificationObservable = AccessibilityObservables.createApplicationNotificationObservable(applicationObservable: applicationObservable, notifications: AppDelegate.windowEvents + [AXNotification.focusedWindowChanged]).share()
        
        let initialWindowFromApplicationObservable: Observable<UIElement?> = applicationObservable
            .map { appOptional in
                guard let app = appOptional else {
                    return nil
                }
                let windowOptional: UIElement? = {
                    do {
                        return try app.attribute(Attribute.focusedWindow)
                    } catch {
                        return nil
                    }
                }()
                return windowOptional
            }
        
        let windowFromApplicationNotificationObservable: Observable<UIElement?> = applicationNotificationObservable
            .map { pair in
                guard let notification = pair.notification,
                    let app = pair.app else {
                    return nil
                }
                
                if notification != .focusedWindowChanged {
                    return nil
                }
                
                let windowOptional: UIElement? = {
                    do {
                        return try app.attribute(Attribute.focusedWindow)
                    } catch {
                        return nil
                    }
                }()
                
                return windowOptional
            }
        
        windowObservable = Observable.merge([windowFromApplicationNotificationObservable, initialWindowFromApplicationObservable])

        hintShortcutObservable = Observable.create { observer in
            MASShortcutMonitor.shared().register(AppDelegate.hintShortcut, withAction: {
                observer.onNext(Void())
            })
            let d = Disposables.create {
                MASShortcutMonitor.shared()?.unregisterShortcut(AppDelegate.hintShortcut)
            }
            return d
        }
        
        scrollShortcutObservable = Observable.create { observer in
            MASShortcutMonitor.shared().register(AppDelegate.scrollShortcut, withAction: {
                observer.onNext(Void())
            })
            let d = Disposables.create {
                MASShortcutMonitor.shared()?.unregisterShortcut(AppDelegate.scrollShortcut)
            }
            return d
        }
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }

        applicationNotificationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { pair in
                if let notification = pair.notification,
                    let app = pair.app {
                    
                    if notification == .focusedWindowChanged {
                        return
                    }

                    self.hideOverlays()
                }
            })
        
        windowObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                self.hideOverlays()
                os_log("Current window: %@", log: Log.accessibility, String(describing: windowOptional))
            })

        let windowNoNilObservable = windowObservable.compactMap { $0 }
        
        hintShortcutObservable
            .withLatestFrom(windowNoNilObservable, resultSelector: { _, window in
                return window
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { window in
                let isHintModeNow = self.hintMode != nil
                self.hideOverlays()
                
                if isHintModeNow {
                    return
                }
                
                self.hintMode = HintMode(applicationWindow: window)
                self.hintMode?.delegate = self
                self.hintMode?.activate()
            })
        
        scrollShortcutObservable
            .withLatestFrom(windowNoNilObservable, resultSelector: { _, window in
                return window
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { window in
                let isScrollModeNow = self.scrollMode != nil
                self.hideOverlays()
                
                if isScrollModeNow {
                    return
                }
                
                self.scrollMode = ScrollMode(applicationWindow: window)
                self.scrollMode?.delegate = self
                self.scrollMode?.activate()
            })
    }
    
    func hideOverlays() {
        hintMode?.deactivate()
        scrollMode?.deactivate()
        hintMode = nil
        scrollMode = nil
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}


extension AppDelegate : ModeDelegate {
    func onDeactivate() {
        hintMode = nil
        scrollMode = nil
    }
}
