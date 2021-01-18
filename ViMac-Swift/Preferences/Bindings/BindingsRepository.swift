//
//  BindingsRepository.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class BindingsRepository {
    func read() -> BindingsConfig {
        BindingsConfig.init(
            hintModeKeySequenceEnabled: BindingsUserDefaults.keySequenceHintModeEnabled.read(),
            hintModeKeySequence: BindingsUserDefaults.keySequenceHintMode.read(),
            scrollModeKeySequenceEnabled: BindingsUserDefaults.keySequenceScrollModeEnabled.read(),
            scrollModeKeySequence: BindingsUserDefaults.keySequenceScrollMode.read(),
            resetDelay: BindingsUserDefaults.keySequenceResetDelay.read()
        )
    }
    
    func readLive() -> Observable<BindingsConfig> {
        Observable.combineLatest(
            BindingsUserDefaults.keySequenceHintModeEnabled.readLive(),
            BindingsUserDefaults.keySequenceHintMode.readLive(),
            BindingsUserDefaults.keySequenceScrollModeEnabled.readLive(),
            BindingsUserDefaults.keySequenceScrollMode.readLive(),
            BindingsUserDefaults.keySequenceResetDelay.readLive()
        ).map({ _ in self.read() })
    }
}
