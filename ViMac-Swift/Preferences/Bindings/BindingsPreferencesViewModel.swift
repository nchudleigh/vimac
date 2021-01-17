//
//  BindingsPreferencesViewModel.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class BindingsPreferencesViewModel {
    enum Event {
        case updateConfig(_ config: BindingsConfig)
    }
    
    struct Model {
        let config: BindingsConfig
    }
    
    private let repo: BindingsRepository
    private let _model: Observable<Model>
    
    let model: Driver<Model>
    
    init() {
        repo = BindingsRepository()
        _model = repo.readLive().map { Model(config: $0) }
        model = _model.asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func accept(_ event: Event) {
        switch event {
        case .updateConfig(let config):
            repo.write(config)
        }
    }
}
