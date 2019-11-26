//
//  AlphabetHints.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 12/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

// Refer to:
// https://github.com/philc/vimium/blob/881a6fdc3644f55fc02ad56454203f654cc76618/content_scripts/link_hints.coffee#L434
class AlphabetHints {
    let linkHintCharacters = "sadfjklewcmpgh"
    let hintKeystrokeQueue: [String] = []
    
    func hintStrings(linkCount: Int) -> [String] {
        if linkCount == 0 {
            return []
        }
        
        var hints = [""]
        var offset = 0
        while hints.count - offset < linkCount || hints.count == 1 {
            let hint = hints[offset]
            offset += 1
            for allowedCharacter in linkHintCharacters {
                hints.append(String(allowedCharacter) + hint)
            }
        }
        return Array(hints[offset...offset+linkCount-1]).sorted().map { String($0.reversed()) }.map { $0.uppercased() }
    }
}
