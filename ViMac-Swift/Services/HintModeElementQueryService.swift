//
//  HintModeWindowQueryService.swift
//  Vimac
//
//  Created by Dexter Leng on 21/7/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift
import AXSwift

class HintModeElementQueryService {
    let windowElement: Element
    lazy var windowQueryService: QueryElementService = QueryElementService(rootElement: windowElement, query: HintModeWindowQuery())
    let disposeBag = DisposeBag()
    
    init(windowElement: Element) {
        self.windowElement = windowElement
    }
    
    func query(onComplete: @escaping ([Element]) -> ()) {
        let elementObservable = Utils.eagerConcat(observables: [
            queryMenuBarObservable().asObservable().flatMap({ Observable.from($0) }),
            queryWindowObservable().asObservable().flatMap({ Observable.from($0) }),
            queryMenuBarExtraObservable().asObservable().flatMap({ Observable.from($0) }),
        ])
        disposeBag.insert(
            elementObservable
                .toArray().asObservable()
                .bind(onNext: { elements in
                    onComplete(elements)
                })
        )
    }
    
    func queryWindowObservable() -> Single<[Element]> {
        return Single.create { [weak self] observer in
            try! self!.windowQueryService.perform(onComplete: { [weak self] store in
                let elements = try! store.flatten(element: self!.windowElement)
                observer(.success(elements))
            })
            return Disposables.create()
        }
    }
    
    func queryMenuBarObservable() -> Single<[Element]> {
        Utils.traverseForMenuBarItems(windowElement: windowElement.cachedUIElement)
            .map { Element(axUIElement: $0.element) }
            .toArray()
    }
    
    func queryMenuBarExtraObservable() -> Single<[Element]> {
        Utils.traverseForExtraMenuBarItems()
            .map { Element(axUIElement: $0.element) }
            .toArray()
    }
}
