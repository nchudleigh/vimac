//
//  ElementStore.swift
//  Vimac
//
//  Created by Dexter Leng on 18/7/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

enum ElementStoreError: Error {
    case ElementNotFound
    case ParentAlreadyExists
}

import Cocoa

class ElementStore {
    private var store: [UUID: Element] = [:]
    private var parent_map: [UUID: Element] = [:]
    private var children_map: [UUID: [Element]] = [:]
    
    func add(element: Element) {
        store[element.uuid] = element
    }
    
    func find(uuid: UUID) -> Element? {
        store[uuid]
    }
    
    func find_exn(uuid: UUID) throws -> Element {
        let elementOptional = find(uuid: uuid)
        guard let element = elementOptional else {
            throw ElementStoreError.ElementNotFound
        }
        return element
    }
    
    func add_parent(element: Element, parent: Element) throws {
        try! validate_element_existence(element: element)
        try! validate_element_existence(element: parent)
        try! validate_parent_absence(element: element)
        
        parent_map[element.uuid] = parent
        var parent_children = try! get_children(element: parent)
        parent_children.append(element)
        children_map[parent.uuid] = parent_children
    }
    
    func get_parent(element: Element) -> Element? {
        parent_map[element.uuid]
    }
    
    func get_parent_exn(element: Element) throws -> Element {
        let parentOptional = get_parent(element: element)
        guard let parent = parentOptional else {
            throw ElementStoreError.ElementNotFound
        }
        return parent
    }
    
    func get_children(element: Element) throws -> [Element] {
        try! validate_element_existence(element: element)
        return children_map[element.uuid] ?? []
    }
    
    func flatten(element: Element) throws -> [Element] {
        try! validate_element_existence(element: element)
        let children = try! get_children(element: element)
        return [element] + children.flatMap { try! flatten(element: $0) }
    }

    private func validate_element_existence(element: Element) throws {
        let elementOptional = find(uuid: element.uuid)
        if elementOptional == nil {
            throw ElementStoreError.ElementNotFound
        }
    }
    
    private func validate_parent_absence(element: Element) throws {
        let parent = get_parent(element: element)
        if parent != nil {
            throw ElementStoreError.ParentAlreadyExists
        }
    }
}
