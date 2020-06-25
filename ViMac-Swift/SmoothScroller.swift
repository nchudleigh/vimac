//
//  SmoothScroller.swift
//  Vimac
//
//  Created by Dexter Leng on 14/6/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class SmoothScroller: Scroller {
    static func instantiate(direction: ScrollDirection) -> SmoothScroller {
        let sensitivity = UserPreferences.ScrollMode.ScrollSensitivityProperty.read()
        
        var xAxis = Int64(0)
        var yAxis = Int64(0)
        
        switch direction {
            case .left:
                xAxis = Int64(sensitivity)
            case .right:
                xAxis = Int64(-sensitivity)
            case .down:
                yAxis = Int64(-sensitivity)
            case .up:
                yAxis = Int64(sensitivity)
            default:
                fatalError("half-<direction> scroll directions should not used for SmoothScroller")
        }
        
        let isHorizontalScrollReversed = UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.read()
        let isVerticalScrollReversed = UserPreferences.ScrollMode.ReverseVerticalScrollProperty.read()
        
        if isHorizontalScrollReversed {
            xAxis = -xAxis
        }
        
        if isVerticalScrollReversed {
            yAxis = -yAxis
        }
        
        let frequency = 1.0 / 50.0
        
        return SmoothScroller.init(frequency: frequency, xAxis: xAxis, yAxis: yAxis)
    }
    
    private let frequency: TimeInterval
    private let xAxis: Int64
    private let yAxis: Int64
    
    private var timer: Timer?
    
    init(frequency: TimeInterval, xAxis: Int64, yAxis: Int64) {
        self.frequency = frequency
        self.xAxis = xAxis
        self.yAxis = yAxis
    }

    // scroll phase 128 signifies the start of a trackpad scroll
    // if an application did not receive this event, the scroll events below will not work
    func emitPhase128() {
        let e = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: 128)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
        e.post(tap: .cghidEventTap)
    }
    
    // this is the second event emitted after 128.
    // if not present the final event (scroll phase 4) will not be allowed to emit (hence rubber banding will not work)
    func emitPhase1() {
        let e = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: 1)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: yAxis)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: xAxis)
        e.post(tap: .cghidEventTap)
    }
    
    // scroll event that is repeatedly emitted
    @objc func emitPhase2() {
        let e = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: yAxis)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: xAxis)
        e.post(tap: .cghidEventTap)
    }
    
    // trackpad "release" event
    // this prevents us from scrolling against the "rubber band" at the end of a scroll area
    // unfortunately it causes the scroll to "glide" at the end, which may not be desirable
    func emitPhase4() {
        let e = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        e.setDoubleValueField(.scrollWheelEventScrollPhase, value: 4)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
        e.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
        e.post(tap: .cghidEventTap)
    }
    
    func start() {
        if let _ = timer {
            fatalError("Do not call start() more than once.")
        }
        
        emitPhase128()
        emitPhase1()
        self.timer = Timer.scheduledTimer(timeInterval: frequency, target: self, selector: #selector(emitPhase2), userInfo: nil, repeats: true)
    }
    
    func stop() {
        emitPhase4()
        timer?.invalidate()
        self.timer = nil
    }
}
