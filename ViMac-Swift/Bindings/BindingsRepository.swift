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
            holdSpaceHintModeActivationEnabled: UserDefaultsProperties.holdSpaceHintModeActivationEnabled.read(),
            hintModeKeySequenceEnabled: UserDefaultsProperties.keySequenceHintModeEnabled.read(),
            hintModeKeySequence: UserDefaultsProperties.keySequenceHintMode.read(),
            scrollModeKeySequenceEnabled: UserDefaultsProperties.keySequenceScrollModeEnabled.read(),
            scrollModeKeySequence: UserDefaultsProperties.keySequenceScrollMode.read(),
            resetDelay: Double(UserDefaultsProperties.keySequenceResetDelay.read()) ?? Double(UserDefaultsProperties.keySequenceResetDelay.defaultValue)!
        )
    }
    
    func readLive() -> Observable<BindingsConfig> {
        Observable.combineLatest(
            UserDefaultsProperties.holdSpaceHintModeActivationEnabled.readLive(),
            UserDefaultsProperties.keySequenceHintModeEnabled.readLive(),
            UserDefaultsProperties.keySequenceHintMode.readLive(),
            UserDefaultsProperties.keySequenceScrollModeEnabled.readLive(),
            UserDefaultsProperties.keySequenceScrollMode.readLive(),
            UserDefaultsProperties.keySequenceResetDelay.readLive()
        ).map({ _ in self.read() })
    }
}
