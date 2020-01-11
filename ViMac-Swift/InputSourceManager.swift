//
//  InputSourceManager.swift
//  kawa
//
//  Created by utatti on 27/07/2015.
//  Copyright (c) 2015-2017 utatti and project contributors.
//  Licensed under the MIT License.
//

import Carbon
import Cocoa

class InputSource: Equatable {
    static func == (lhs: InputSource, rhs: InputSource) -> Bool {
        return lhs.id == rhs.id
    }

    let tisInputSource: TISInputSource
    let icon: NSImage?

    var id: String {
        return tisInputSource.id
    }

    var name: String {
        return tisInputSource.name
    }

    var isCJKV: Bool {
        if let lang = tisInputSource.sourceLanguages.first {
            return lang == "ko" || lang == "ja" || lang == "vi" || lang.hasPrefix("zh")
        }
        return false
    }

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource

        var iconImage: NSImage? = nil

        if let imageURL = tisInputSource.iconImageURL {
            for url in [imageURL.retinaImageURL, imageURL.tiffImageURL, imageURL] {
                if let image = NSImage(contentsOf: url) {
                    iconImage = image
                    break
                }
            }
        }

        if iconImage == nil, let iconRef = tisInputSource.iconRef {
            iconImage = NSImage(iconRef: iconRef)
        }

        self.icon = iconImage
    }

    func select() {
        TISSelectInputSource(tisInputSource)

        if isCJKV, let selectPreviousShortcut = InputSourceManager.getSelectPreviousShortcut() {
            // Workaround for TIS CJKV layout bug:
            // when it's CJKV, select nonCJKV input first and then return
            if let nonCJKV = InputSourceManager.nonCJKVSource() {
                nonCJKV.select()
                InputSourceManager.selectPrevious(shortcut: selectPreviousShortcut)
            }
        }
    }
}

class InputSourceManager {
    static var inputSources: [InputSource] = []

    static func initialize() {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        inputSources = inputSourceList.filter({
            $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable
        }).map { InputSource(tisInputSource: $0) }
    }
    
    static func nonCJKVSource() -> InputSource? {
        return inputSources.first(where: { !$0.isCJKV })
    }

    static func selectPrevious(shortcut: (Int, UInt64)) {
        let src = CGEventSource(stateID: .hidSystemState)

        let key = CGKeyCode(shortcut.0)
        let flag = CGEventFlags(rawValue: shortcut.1)

        let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)!
        let up = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)!

        down.flags = flag;
        up.flags = flag;

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    // from read-symbolichotkeys script of Karabiner
    // github.com/tekezo/Karabiner/blob/master/src/util/read-symbolichotkeys/read-symbolichotkeys/main.m
    static func getSelectPreviousShortcut() -> (Int, UInt64)? {
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.symbolichotkeys") else {
            return nil
        }
        guard let symbolichotkeys = dict["AppleSymbolicHotKeys"] as! NSDictionary? else {
            return nil
        }
        guard let symbolichotkey = symbolichotkeys["60"] as! NSDictionary? else {
            return nil
        }
        if (symbolichotkey["enabled"] as! NSNumber).intValue != 1 {
            return nil
        }
        guard let value = symbolichotkey["value"] as! NSDictionary? else {
            return nil
        }
        guard let parameters = value["parameters"] as! NSArray? else {
            return nil
        }
        return (
            (parameters[1] as! NSNumber).intValue,
            (parameters[2] as! NSNumber).uint64Value
        )
    }
}

private extension URL {
    var retinaImageURL: URL {
        var components = pathComponents
        let filename: String = components.removeLast()
        let ext: String = pathExtension
        let retinaFilename = filename.replacingOccurrences(of: "." + ext, with: "@2x." + ext)
        return NSURL.fileURL(withPathComponents: components + [retinaFilename])!
    }

    var tiffImageURL: URL {
        return deletingPathExtension().appendingPathExtension("tiff")
    }
}
