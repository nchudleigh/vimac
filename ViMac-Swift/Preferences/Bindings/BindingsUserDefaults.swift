//
//  BindingsUserDefaults.swift
//  Vimac
//
//  Created by Dexter Leng on 17/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa

struct BindingsUserDefaults {
    static let keySequenceHintModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceHintModeEnabled")
    static let keySequenceHintMode = UserDefaultsProperty<String>.init("keySequenceHintMode")
    static let keySequenceScrollModeEnabled = UserDefaultsProperty<Bool>.init("keySequenceScrollModeEnabled")
    static let keySequenceScrollMode = UserDefaultsProperty<String>.init("keySequenceScrollMode")
    static let keySequenceResetDelay = UserDefaultsProperty<TimeInterval>.init("keySequenceResetDelay")
}
