//
//  CachedUIElement.swift
//  Vimac
//
//  Created by Dexter Leng on 2/11/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class CachedUIElement: UIElement {
    var cache: [Attribute:Any] = [:]
    var actionsCache: [String]?
    
    required init(_ nativeElement: AXUIElement) {
        super.init(nativeElement)
    }
    
    override func getMultipleAttributes(_ names: Attribute...) throws -> [Attribute : Any] {
        return try self.getMultipleAttributes(names)
    }
    
    override func getMultipleAttributes(_ attributes: [Attribute]) throws -> [Attribute : Any] {
        let allAttributesFetched = Set(attributes).isSubset(of: cache.keys)
        if allAttributesFetched {
            var result: [Attribute : Any] = [:]
            for attribute in attributes {
                result[attribute] = cache[attribute]
            }
            return result
        }
        
        let result = try super.getMultipleAttributes(attributes)
        for (attribute, value) in result {
            cache[attribute] = value
        }
        return result
    }
    
    override func attribute<T>(_ attribute: Attribute) throws -> T? {
        if cache.keys.contains(attribute) {
            return cache[attribute] as? T
        }
        return try super.attribute(attribute)
    }
    
    override func actionsAsStrings() throws -> [String] {
        if let actionsCache = actionsCache {
            return actionsCache
        }
        
        actionsCache = try super.actionsAsStrings()
        return actionsCache!
    }
}
