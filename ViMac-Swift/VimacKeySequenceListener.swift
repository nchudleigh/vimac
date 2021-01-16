//
//  VimacKeySequenceListener.swift
//  Vimac
//
//  Created by Dexter Leng on 14/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import RxRelay

class VimacKeySequenceListener {
    struct KeySequenceConfig {
        let hintModeEnabled: Bool
        let hintModeSequence: [Character]
        let scrollModeEnabled: Bool
        let scrollModeSequence: [Character]
        let resetDelay: TimeInterval
    }
    
    struct State {
        let config: KeySequenceConfig
        let enabled: Bool
    }
    
    private let disposeBag = DisposeBag()
    private let _enabled = BehaviorSubject(value: false)

    private var listener: KeySequenceListener?
    
    private let hintModeRelay: PublishRelay<Void> = .init()
    lazy var hintMode = hintModeRelay.asObservable()
    
    private let scrollModeRelay: PublishRelay<Void> = .init()
    lazy var scrollMode = scrollModeRelay.asObservable()
    
    init() {
        let model = modelObservable(configObservable: configObservable(), enabledObservable: enabledObservable())
        disposeBag.insert(model.bind(onNext: { [weak self] model in
            self?.renderListener(model)
        }))
    }
    
    func start() {
        _enabled.onNext(true)
    }
    
    func stop() {
        _enabled.onNext(false)
    }
    
    private func onHintModeSequenceTyped() {
        hintModeRelay.accept(())
    }
    
    private func onScrollModeSequenceTyped() {
        scrollModeRelay.accept(())
    }
    
    private func renderListener(_ state: State) {
        let config = state.config
        let enabled = state.enabled
        
        listener?.stop()
        listener = nil

        if !enabled {
            return
        }

        listener = createKeySequenceListener(config: config)
        listener?.start()
        
        listener?.matchEvents.bind(onNext: { [weak self] sequence in
            guard let self = self else { return }
            
            if sequence == config.hintModeSequence {
                self.onHintModeSequenceTyped()
            } else if sequence == config.scrollModeSequence {
                self.onScrollModeSequenceTyped()
            }
        }).disposed(by: disposeBag)
    }
    
    private func modelObservable(configObservable: Observable<KeySequenceConfig>, enabledObservable: Observable<Bool>) -> Observable<State> {
        Observable.combineLatest(configObservable, enabledObservable)
            .map({ State.init(config: $0, enabled: $1) })
    }
    
    private func configObservable() -> Observable<KeySequenceConfig> {
        Observable.create { observer in
            observer.onNext(.init(hintModeEnabled: true, hintModeSequence: ["f", "d"], scrollModeEnabled: true, scrollModeSequence: ["j", "k"], resetDelay: 0.25))
            return Disposables.create()
        }
    }
    
    private func enabledObservable() -> Observable<Bool> {
        _enabled.distinctUntilChanged()
    }
    
    func createKeySequenceListener(config: KeySequenceConfig) -> KeySequenceListener {
        let listener = KeySequenceListener(resetDelay: config.resetDelay)
        
        if config.hintModeEnabled {
            try! listener.registerSequence(seq: config.hintModeSequence)
        }
        if config.scrollModeEnabled {
            try! listener.registerSequence(seq: config.scrollModeSequence)
        }
        return listener
    }
}
