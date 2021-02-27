//
//  BindingsUserDefaults.swift
//  Vimac
//
//  Created by Dexter Leng on 17/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

struct BindingsUserDefaults {
    static let keySequenceHintModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceHintModeEnabled", defaultValue: false)
    static let keySequenceHintMode = UserDefaultsProperty<String>.init("keySequenceHintMode", defaultValue: "")
    static let keySequenceScrollModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceScrollModeEnabled", defaultValue: false)
    static let keySequenceScrollMode = UserDefaultsProperty<String>.init("keySequenceScrollMode", defaultValue: "")
    static let keySequenceResetDelay = UserDefaultsProperty<TimeInterval>.init("keySequenceResetDelay", defaultValue: 0.25)
}
