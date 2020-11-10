//
//  Trie.swift
//  Vimac
//
//  Created by Dexter Leng on 8/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class TrieNode {
    private var children: Dictionary<Character, TrieNode>
    private var terminates: Bool
    let character: Character
    let parent: TrieNode?

    init(character: Character, terminates: Bool, parent: TrieNode?) {
        self.character = character
        self.children = .init()
        self.terminates = terminates
        self.parent = parent
    }

    func set(terminates: Bool) {
        self.terminates = terminates
    }

    func addWord(_ word: [Character]) {
        if (word.count == 0) {
            return
        }

        let firstChar = word.first!

        var childOptional = getChild(c: firstChar)
        if childOptional == nil {
            childOptional = TrieNode(character: firstChar, terminates: false, parent: self)
            children[firstChar] = childOptional
        }
        let child = childOptional!

        if word.count > 1 {
            child.addWord(word.dropFirst().compactMap({ $0 }))
        } else {
            child.set(terminates: true)
        }
    }

    func getChildren() -> [TrieNode] {
        children.values.compactMap({ $0 })
    }

    func getChild(c: Character) -> TrieNode? {
        children[c]
    }

    func isTerminating() -> Bool {
        terminates
    }
}

class Trie {
    let root: TrieNode

    init() {
        // garbage character
        root = TrieNode(character: "n", terminates: false, parent: nil)
    }
    
    func addWord(_ word: [Character]) {
        root.addWord(word)
    }
    
    func isPrefix(_ word: [Character]) -> Bool {
        var lastNode: TrieNode? = root
        for c in word {
            lastNode = lastNode!.getChild(c: c)
            if lastNode == nil {
                return false
            }
        }
        return true
    }
    
    func contains(_ word: [Character]) -> Bool {
        var lastNode: TrieNode? = root
        for c in word {
            lastNode = lastNode!.getChild(c: c)
            if lastNode == nil {
                return false
            }
        }
        return lastNode!.isTerminating()
    }
    
    func doesPrefixWordExist(_ word: [Character]) -> Bool {
        var lastNode: TrieNode? = root
        for c in word {
            let newLastNode = lastNode!.getChild(c: c)
            if newLastNode == nil {
                return lastNode!.isTerminating()
            }
            lastNode = newLastNode
        }
        return lastNode!.isTerminating()
    }
}
