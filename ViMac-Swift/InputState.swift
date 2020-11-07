//
//  InputState.swift
//  Vimac
//
//  Created by Dexter Leng on 15/9/20.
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

    init(_ words: [[Character]]) {
        // garbage character
        root = TrieNode(character: "n", terminates: false, parent: nil)
        for word in words {
            root.addWord(word)
        }
    }

    func contains(prefix: [Character], exact: Bool) -> Bool {
        var lastNode: TrieNode? = root
        for c in prefix {
            lastNode = lastNode!.getChild(c: c)
            if lastNode == nil {
                return false
            }
        }
        return !exact || lastNode!.isTerminating()
    }
}


class InputState {
    enum Event {
        case match(keySequence: [Character])
        case unmatchableSequence
    }

    let keySequences: [[Character]]
    let trie: Trie
    var state: TrieNode
    let commonPrefixDelaySeconds: Double
    let enteredKeySequence: [Character] = []
    var listener: (([Character]) -> ())?

    var commonPrefixTimer: Timer?

    init(keySequences: [[Character]], commonPrefixDelaySeconds: Double) {
        self.commonPrefixDelaySeconds = commonPrefixDelaySeconds
        self.keySequences = keySequences
        self.trie = Trie(keySequences)
        self.state = trie.root
    }
    
    deinit {
        clearTimer()
    }

    func advance(_ c: Character) -> Bool {

        clearTimer()

        let newState = self.state.getChild(c: c)
        if newState == nil {
            return false
        }
        self.state = newState!

        let sequence: [Character] = {
            var seqRev: [Character] = []
            var s: TrieNode? = state
            while s != nil {
                seqRev.append(s!.character)
                s = s!.parent
            }
            // pop root node's garbage character
            seqRev.popLast()
            return seqRev.reversed()
        }()

        if self.state.isTerminating() {
            if self.state.getChildren().count > 0 {
                delayAlertListeners(sequence)
            } else {
                self.alertListeners(sequence)
            }
        }

        return true
    }

    func resetState() {
        clearTimer()
        self.state = trie.root
    }

    // start timer that waits commonPrefixDelayMs before calling listener
    private func delayAlertListeners(_ sequence: [Character]) {
        clearTimer()
        commonPrefixTimer = Timer.scheduledTimer(
            withTimeInterval: commonPrefixDelaySeconds,
            repeats: false,
            block: { [weak self] _ in
                self?.alertListeners(sequence)
            })
    }

    private func clearTimer() {
        self.commonPrefixTimer?.invalidate()
        self.commonPrefixTimer = nil
    }

    private func alertListeners(_ sequence: [Character]) {
        self.listener?(sequence)
        resetState()
    }

    func registerListener(_ listener: @escaping ([Character]) -> ()) {
        self.listener = listener
    }
}
