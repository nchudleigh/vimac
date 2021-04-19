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
    struct State {
        let config: BindingsConfig
        let enabled: Bool
    }
    
    private let disposeBag = DisposeBag()
    private let _enabled = BehaviorSubject(value: false)

    private var listener: KeySequenceListener?
    
    private let hintModeRelay: PublishRelay<Void> = .init()
    lazy var hintMode = hintModeRelay.asObservable()
    
    private let scrollModeRelay: PublishRelay<Void> = .init()
    lazy var scrollMode = scrollModeRelay.asObservable()
    
    private let configRepo = BindingsRepository()
    
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
        
        if !config.hintModeKeySequenceEnabled && !config.scrollModeKeySequenceEnabled {
            return
        }

        listener = createKeySequenceListener(config: config)
        listener?.start()
        
        listener?.matchEvents.bind(onNext: { [weak self] sequence in
            guard let self = self else { return }
            
            if String(sequence) == config.hintModeKeySequence {
                self.onHintModeSequenceTyped()
            } else if String(sequence) == config.scrollModeKeySequence {
                self.onScrollModeSequenceTyped()
            }
        }).disposed(by: disposeBag)
    }
    
    private func modelObservable(configObservable: Observable<BindingsConfig>, enabledObservable: Observable<Bool>) -> Observable<State> {
        Observable.combineLatest(configObservable, enabledObservable)
            .map({ State.init(config: $0, enabled: $1) })
    }
    
    private func configObservable() -> Observable<BindingsConfig> {
        configRepo.readLive()
    }
    
    private func enabledObservable() -> Observable<Bool> {
        _enabled.distinctUntilChanged()
    }
    
    func createKeySequenceListener(config: BindingsConfig) -> KeySequenceListener? {
        var sequences: [[Character]] = []
        if config.hintModeKeySequenceEnabled && config.hintModeKeySequence.count > 1 {
            sequences.append(Array(config.hintModeKeySequence))
        }
        if config.scrollModeKeySequenceEnabled && config.scrollModeKeySequence.count > 1 {
            sequences.append(Array(config.scrollModeKeySequence))
        }
        
        return KeySequenceListener(sequences: sequences, resetDelay: config.resetDelay)
    }
}
