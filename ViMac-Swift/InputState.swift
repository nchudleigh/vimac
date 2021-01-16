//
//  InputState.swift
//  Vimac
//
//  Created by Dexter Leng on 8/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import Cocoa

class InputState {
    enum State {
        case initialized
        case wordsAdded
        case advancable
        case deadend
        case matched
    }
    
    enum StateMachineError: Error {
        case invalidTransition
    }
    
    private var trie: Trie
    private var currentTrieNode: TrieNode
    private(set) public var state: State
    
    init() {
        self.trie = Trie()
        self.currentTrieNode = trie.root
        self.state = .initialized
    }

    func addWord(_ word: [Character]) throws -> Bool {
        if state != .initialized && state != .wordsAdded {
            throw StateMachineError.invalidTransition
        }
        
        if self.trie.isPrefix(word) || self.trie.doesPrefixWordExist(word) {
            return false
        }

        self.trie.addWord(word)
        self.state = .wordsAdded
        return true
    }

    func advance(_ c: Character) throws {
        if state != .advancable && state != .wordsAdded {
            throw StateMachineError.invalidTransition
        }
        
        guard let newCurrentTrieNode = self.currentTrieNode.getChild(c: c) else {
            self.state = .deadend
            return
        }

        self.currentTrieNode = newCurrentTrieNode

        if self.currentTrieNode.isTerminating() {
            assert(self.currentTrieNode.getChildren().count == 0)
            self.state = .matched
            return
        }
        
        self.state = .advancable
    }

    func matchedWord() throws -> [Character] {
        if state != .matched {
            throw StateMachineError.invalidTransition
        }
        return typed()
    }
    
    private func typed() -> [Character] {
        var seqRev: [Character] = []
        var s: TrieNode? = self.currentTrieNode
        while s != nil {
            seqRev.append(s!.character)
            s = s!.parent
        }
        // pop root node's garbage character
        seqRev.popLast()
        return seqRev.reversed()
    }

    func resetInput() {
        self.currentTrieNode = self.trie.root
        self.state = .wordsAdded
    }
}
