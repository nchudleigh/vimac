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
        if let application = NSWorkspace.shared.frontmostApplication {
            let axSwiftApp = Application.init(forProcessID: application.processIdentifier)!
            let focusedWindow: UIElement = try! axSwiftApp.attribute(Attribute.focusedWindow)!
            traverseUIElementForButtons(element: focusedWindow, level: 1)
        }
    }
    
    func traverseUIElementForButtons(element: UIElement, level: Int) {
        let role = try! element.role();
        if (role == Role.button) {
            if let position: CGPoint = try! element.attribute(.position),
                let size: CGSize = try! element.attribute(.size) {
                print(element)
                print(position)
                print(size)
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
        
        let children = try! element.attribute(Attribute.children) as [AXUIElement]?;
        if let c = children {
            for child in c {
                traverseUIElementForButtons(element: UIElement.init(child), level: level + 1)
            }
        }
    }
    
    func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        let screenHeight = NSScreen.screens.first?.frame.size.height
        return CGPoint(x: point.x, y: screenHeight! - size.height - point.y)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

