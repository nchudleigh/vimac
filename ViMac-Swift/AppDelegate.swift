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
    let storyboard: NSStoryboard
    let hintShortcut: MASShortcut
    let scrollShortcut: MASShortcut
    
    let applicationObservable: Observable<Application?>
    let applicationNotificationObservable: Observable<AccessibilityObservables.AppNotificationAppPair>
    let windowSubject: BehaviorSubject<UIElement?>
    let overlayEventSubject: PublishSubject<OverlayEvent>
    
    var scrollMode: ScrollMode?
    var hintMode: HintMode?

    static let windowEvents: [AXNotification] = [.windowMiniaturized, .windowMoved, .windowResized]
    
    override init() {
        storyboard =
            NSStoryboard.init(name: "Main", bundle: nil)
        applicationObservable = AccessibilityObservables.createApplicationObservable().share()
        applicationNotificationObservable = AccessibilityObservables.createApplicationNotificationObservable(applicationObservable: applicationObservable, notifications: AppDelegate.windowEvents + [AXNotification.focusedWindowChanged])
        windowSubject = BehaviorSubject(value: nil)
        overlayEventSubject = PublishSubject()
        hintShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .option, .control])
        scrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_C, modifierFlags: [.command, .option, .control])
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        applicationObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { appOptional in
                if let app = appOptional {
                    let windowOptional: UIElement? = {
                        do {
                            return try app.attribute(Attribute.focusedWindow)
                        } catch {
                            return nil
                        }
                    }()
                    self.windowSubject.onNext(windowOptional)
                }
            })

        applicationNotificationObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { pair in
                if let notification = pair.notification,
                    let app = pair.app {
                    if notification == .focusedWindowChanged {
                        let windowOptional: UIElement? = {
                            do {
                                return try app.attribute(Attribute.focusedWindow)
                            } catch {
                                return nil
                            }
                        }()
                        self.windowSubject.onNext(windowOptional)
                        return
                    }
                    
                    if (AppDelegate.windowEvents.contains(notification)) {
                        self.overlayEventSubject.onNext(.activeWindowUpdated)
                        return
                    }
                }
            })
        
        windowSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                os_log("Current window: %@", log: Log.accessibility, String(describing: windowOptional))
                guard let window = windowOptional else {
                    self.overlayEventSubject.onNext(.noActiveWindow)
                    return
                }
                
                self.overlayEventSubject.onNext(.newActiveWindow)
            })
        
        overlayEventSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { event in
                switch event {
                case .newActiveWindow:
                    self.hideOverlays()
                case .noActiveWindow:
                    self.hideOverlays()
                case .activeWindowUpdated:
                    self.hideOverlays()
                case .hintCommandPressed:
                    let isHintModeNow = self.hintMode != nil
                    self.hideOverlays()

                    if isHintModeNow {
                        return
                    }
                    
                    let windowOptional: UIElement? = {
                        do {
                            return try self.windowSubject.value()
                        } catch {
                            return nil
                        }
                    }()
                    
                    guard let window = windowOptional else {
                        return
                    }
                    
                    self.hintMode = HintMode(applicationWindow: window)
                    self.hintMode?.activate()
                case .scrollCommandPressed:
                    let isScrollModeNow = self.scrollMode != nil
                    self.hideOverlays()
                    
                    if isScrollModeNow {
                        return
                    }
                    
                    let windowOptional: UIElement? = {
                        do {
                            return try self.windowSubject.value()
                        } catch {
                            return nil
                        }
                    }()
                    
                    guard let window = windowOptional else {
                        return
                    }
                    
                    self.scrollMode = ScrollMode(applicationWindow: window)
                    self.scrollMode?.activate()
                }
            })
        
        MASShortcutMonitor.shared().register(hintShortcut, withAction: {
            self.overlayEventSubject.onNext(.hintCommandPressed)
        })
        
        MASShortcutMonitor.shared().register(scrollShortcut, withAction: {
            self.overlayEventSubject.onNext(.scrollCommandPressed)
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
        
    }
}
