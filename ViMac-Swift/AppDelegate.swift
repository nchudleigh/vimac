//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var controllers: [NSWindowController]
    var storyboard: NSStoryboard
    
    override init() {
        controllers = [NSWindowController]()
        storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that we have permission
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }

        // Get Active Application
        if let application = NSWorkspace.shared.frontmostApplication,
            let axSwiftApp = Application.init(forProcessID: application.processIdentifier),
            let focusedWindow: UIElement = try! axSwiftApp.attribute(Attribute.focusedWindow) {

            let buttons = traverseUIElementForButtons(element: focusedWindow, level: 1)
            for button in buttons {
                if let position: CGPoint = try! button.attribute(.position),
                    let size: CGSize = try! button.attribute(.size) {
                    let controller = storyboard.instantiateController(withIdentifier: "overlayWindowControllerID") as! NSWindowController
                    let frame = controller.window?.frame
                    if var uFrame = frame {
                        uFrame.origin = toOrigin(point: position, size: size)
                        uFrame.size = size
                        controller.window?.setFrame(uFrame, display: true, animate: false)
                        controller.window?.orderFront(nil)
                    }
    
                    controller.showWindow(nil)
                    controllers.append(controller)
                }
            }
        }
    }
    
    func traverseUIElementForButtons(element: UIElement, level: Int) -> [UIElement] {
        let role = try! element.role();
        if (role == Role.button) {
            return [element]
        }
        
        let children = try! element.attribute(Attribute.children) as [AXUIElement]?;
        if let unwrappedChildren = children {
            return unwrappedChildren
                .map({child -> [UIElement] in
                    return traverseUIElementForButtons(element: UIElement.init(child), level: level + 1)
                })
                .reduce([]) {(result, next) -> [UIElement] in
                    return result + next
                }
        }
        return []
    }
    
    func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        let screenHeight = NSScreen.screens.first?.frame.size.height
        return CGPoint(x: point.x, y: screenHeight! - size.height - point.y)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

