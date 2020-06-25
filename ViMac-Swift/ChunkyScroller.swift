//
//  ChunkyScroller.swift
//  Vimac
//
//  Created by Dexter Leng on 14/6/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class ChunkyScroller: Scroller {
    static func instantiate(direction: ScrollDirection, scrollAmount: Int) -> ChunkyScroller {
        var xAxis = Int64(0)
        var yAxis = Int64(0)
        
        switch direction {
            case .halfLeft:
                xAxis = Int64(scrollAmount)
            case .halfRight:
                xAxis = Int64(-scrollAmount)
            case .halfDown:
                yAxis = Int64(-scrollAmount)
            case .halfUp:
                yAxis = Int64(scrollAmount)
            default:
                fatalError("<direction> scroll directions should not used for SmoothScroller")
        }
        
        let isHorizontalScrollReversed = UserPreferences.ScrollMode.ReverseHorizontalScrollProperty.read()
        let isVerticalScrollReversed = UserPreferences.ScrollMode.ReverseVerticalScrollProperty.read()
        
        if isHorizontalScrollReversed {
            xAxis = -xAxis
        }
        
        if isVerticalScrollReversed {
            yAxis = -yAxis
        }
        
        let frequency = 0.25
        
        return ChunkyScroller.init(frequency: frequency, xAxis: xAxis, yAxis: yAxis)
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
    
    @objc func emitScrollEvent() {
        let event = CGEvent.init(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)!
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: yAxis)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: xAxis)
        event.post(tap: .cghidEventTap)
    }
    
    func start() {
        if let _ = timer {
            fatalError("Do not call start() more than once.")
        }
        
        emitScrollEvent()
        self.timer = Timer.scheduledTimer(timeInterval: frequency, target: self, selector: #selector(emitScrollEvent), userInfo: nil, repeats: true)
    }
    
    func stop() {
        timer?.invalidate()
        self.timer = nil
    }
}
