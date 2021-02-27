//
//  UserDefautsProperty.swift
//  Vimac
//
//  Created by Dexter Leng on 17/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

public struct UserDefaultsProperty<ValueType: Any> {
    public let key: String
    public let defaultValue: ValueType
    
    public init(_ key: String, defaultValue: ValueType) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    func write(_ v: ValueType) {
        UserDefaults.standard.set(v, forKey: self.key)
    }
    
    func read() -> ValueType {
        (UserDefaults.standard.object(forKey: self.key) as? ValueType) ?? defaultValue
    }
    
    func readLive() -> Observable<ValueType> {
        UserDefaults.standard.rx.observe(Any.self, self.key).map({ ($0 as? ValueType) ?? self.defaultValue })
    }
}

