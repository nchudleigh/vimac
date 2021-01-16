//
//  GlobalEventTap.swift
//  Vimac
//
//  Created by Dexter Leng on 1/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Foundation

class GlobalEventTap {
    let eventMask: CGEventMask
    let eventHandler: (CGEvent) -> CGEvent?
    
    var runLoopSource: CFRunLoopSource?
    var eventTap: CFMachPort?
    var selfPtr: Unmanaged<GlobalEventTap>!
    
    init(eventMask: CGEventMask, onEvent: @escaping (CGEvent) -> CGEvent?) {
        self.eventMask = eventMask
        self.eventHandler = onEvent
        selfPtr = Unmanaged.passRetained(self)
    }
    
    func enabled() -> Bool {
        guard let tap = eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }
    
    func enable() {
        if let tap = eventTap {
            if CGEvent.tapIsEnabled(tap: tap) {
                return
            } else {
                CFMachPortInvalidate(tap)
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                self.eventTap = nil
                self.runLoopSource = nil
            }
        }

        self.eventTap = createEventTap()
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: self.eventTap!, enable: true)
    }
    
    func disable() {
        if let tap = eventTap {
            if CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: false)
            }
            
            CFMachPortInvalidate(tap)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }
    
    private func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        if type == CGEventType.tapDisabledByUserInput {
            return nil
        }
        
        let e = self.eventHandler(event)
        if let e = e {
            return Unmanaged.passRetained(e).autorelease()
        }
        
        return nil
    }
    
    private func createEventTap() -> CFMachPort {
        let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: eventMask, callback: { proxy, type, event, refcon in
            // Trick from https://stackoverflow.com/questions/33260808/how-to-use-instance-method-as-callback-for-function-which-takes-only-func-or-lit
            let mySelf = Unmanaged<GlobalEventTap>.fromOpaque(refcon!).takeUnretainedValue()
            return mySelf.eventTapCallback(proxy: proxy, type: type, event: event, refcon: refcon)
        },
        userInfo: selfPtr.toOpaque())!
        return eventTap
    }
}
