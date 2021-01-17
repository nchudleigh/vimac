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
            hintModeKeySequenceEnabled: BindingsUserDefaults.keySequenceHintModeEnabled.read() ?? false,
            hintModeKeySequence: BindingsUserDefaults.keySequenceHintMode.read() ?? "",
            scrollModeKeySequenceEnabled: BindingsUserDefaults.keySequenceScrollModeEnabled.read() ?? false,
            scrollModeKeySequence: BindingsUserDefaults.keySequenceScrollMode.read() ?? "",
            resetDelay: BindingsUserDefaults.keySequenceResetDelay.read() ?? 0.25
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
    
    func write(_ config: BindingsConfig) {
        BindingsUserDefaults.keySequenceHintModeEnabled.write(config.hintModeKeySequenceEnabled)
        BindingsUserDefaults.keySequenceHintMode.write(config.hintModeKeySequence)
        BindingsUserDefaults.keySequenceScrollModeEnabled.write(config.scrollModeKeySequenceEnabled)
        BindingsUserDefaults.keySequenceScrollMode.write(config.scrollModeKeySequence)
        BindingsUserDefaults.keySequenceResetDelay.write(config.resetDelay)
    }
}
