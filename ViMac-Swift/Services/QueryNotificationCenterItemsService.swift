//
//  QueryNotificationCenterItemsService.swift
//  Vimac
//
//  Created by Dexter Leng on 8/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift

class QueryNotificationCenterItemsService {
    func perform() throws -> [Element]? {
        let notificationAppOptional = NSWorkspace.shared.runningApplications
            .first(where: { $0.localizedName == "Notification Centre" })
        guard let notificationApp = notificationAppOptional,
            let notificationAppUIElement = Application(notificationApp) else {
            return nil
        }
        
        let windows = (try? notificationAppUIElement.windows()) ?? []
        let windowChildrenUnflattened = windows.map({ actionableChildren($0.element) })
        let windowChildren = Array(windowChildrenUnflattened.joined())
        return windowChildren
            .map { Element.initialize(rawElement: $0) }
            .compactMap({ $0 })
    }
    
    func actionableChildren(_ element: AXUIElement) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var stack: [AXUIElement] = [element ]
        while stack.count > 0 {
            let head = stack.popLast()!
            let actions = (try? UIElement(head).actionsAsStrings()) ?? []
            if actions.count > 0 {
                result.append(head)
            }
            let children: [AXUIElement] = (try? UIElement(head).attribute(.children)) ?? []
            stack.append(contentsOf: children)
        }
        return result
    }
}
