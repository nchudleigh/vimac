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
    
    public init(_ key: String) {
        self.key = key
    }
    
    func write(_ v: ValueType) {
        UserDefaults.standard.set(v, forKey: self.key)
    }
    
    func read() -> ValueType? {
        UserDefaults.standard.object(forKey: self.key) as? ValueType
    }
    
    func readLive() -> Observable<ValueType?> {
        UserDefaults.standard.rx.observe(Any.self, self.key).map({ $0 as? ValueType })
    }
}

