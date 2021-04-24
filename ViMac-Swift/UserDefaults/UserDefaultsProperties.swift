//
//  UserDefaultsProperties.swift
//  Vimac
//
//  Created by Dexter Leng on 6/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

struct UserDefaultsProperties {
    static let holdSpaceHintModeActivationEnabled = UserDefaultsProperty<Bool>.init("holdSpaceHintModeActivationEnabled", defaultValue: true)
    static let keySequenceHintModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceHintModeEnabled", defaultValue: false)
    static let keySequenceHintMode = UserDefaultsProperty<String>.init("keySequenceHintMode", defaultValue: "")
    static let keySequenceScrollModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceScrollModeEnabled", defaultValue: false)
    static let keySequenceScrollMode = UserDefaultsProperty<String>.init("keySequenceScrollMode", defaultValue: "")
    static let keySequenceResetDelay = UserDefaultsProperty<String>.init("keySequenceResetDelay", defaultValue: "0.25")
    
    static let AXEnhancedUserInterfaceEnabled = UserDefaultsProperty<Bool>.init("AXEnhancedUserInterfaceEnabled", defaultValue: false)
    static let AXManualAccessibilityEnabled = UserDefaultsProperty<Bool>.init("AXManualAccessibilityEnabled", defaultValue: false)
}
