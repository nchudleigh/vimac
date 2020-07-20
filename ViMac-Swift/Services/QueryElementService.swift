//
//  QueryElementService.swift
//  Vimac
//
//  Created by Dexter Leng on 18/7/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

struct ElementQueryAction {
    let includeElement: Bool
    // children will only be visited if includeElement == true
    let visitChildren: Bool
    // must be non-null if visitChildren == true
    let childrenContext: [String:Any]?
}

protocol ElementQuery {
    func onElement(element: Element, context: [String:Any]) -> ElementQueryAction
}

class QueryElementService {
    let store = ElementStore()
    let rootElement: Element
    let query: ElementQuery
    let element_store_mutating_queue = DispatchQueue(label: "element_store_mutating_queue")
    
    let disposeBag = DisposeBag()
    
    init(rootElement: Element, query: ElementQuery) {
        self.rootElement = rootElement
        self.query = query
    }
    
    func perform(onComplete: @escaping (ElementStore) -> ()) throws {
        let visitElementObservable = createVisitElementObservable(element: rootElement, parent: nil, context: [String:Any]())
        disposeBag.insert(visitElementObservable.bind(onNext: {
            onComplete(self.store)
        }))
    }
    
    func createVisitElementObservable(element: Element, parent: Element?, context: [String:Any]) -> Observable<Void> {
        let registerParentRelationshipObservable = createRegisterParentRelationshipObservable(element: element, parent: parent)
        let onElementObservable = createOnElementObservable(query: query, element: element, context: context)
        
        let chainedObservable = onElementObservable
            .flatMap({ queryAction -> Observable<(Void, ElementQueryAction, [Element])> in
                if !queryAction.includeElement {
                    return Observable.empty()
                }
                
                if queryAction.visitChildren {
                    let visitChildrenObservable = self.createElementChildrenObservable(element: element)
                    return Observable.zip(registerParentRelationshipObservable, Observable.just(queryAction), visitChildrenObservable)
                }
                
                return Observable.zip(registerParentRelationshipObservable, Observable.just(queryAction), Observable.just([]))
            })
            .flatMap({ (_, queryAction, children) -> Observable<Void> in
                let visitChildrenObservables = children.map({ child in
                    return self.createVisitElementObservable(element: child, parent: element, context: queryAction.childrenContext!)
                })
                return Observable.merge(visitChildrenObservables)
            })
            .toArray()
            .asObservable()
            .map({ _ -> Void in
                return Void()
            })
        return chainedObservable
    }
    
    func createOnElementObservable(query: ElementQuery, element: Element, context: [String:Any]) -> Observable<ElementQueryAction> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                let queryAction = query.onElement(element: element, context: context)
                observer.onNext(queryAction)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    func createRegisterParentRelationshipObservable(element: Element, parent: Element?) -> Observable<Void> {
        return Observable.create({ observer in
            self.element_store_mutating_queue.sync {
                self.store.add(element: element)
                if let parent = parent {
                    try! self.store.add_parent(element: element, parent: parent)
                }

                observer.onNext(Void())
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }

    func createElementChildrenObservable(element: Element) -> Observable<[Element]> {
        return Observable.create({ observer in
            DispatchQueue.global().async {
                let children = element.children()
                observer.onNext(children)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
}
