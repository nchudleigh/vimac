//
//  TrieTests.swift
//  VimacTests
//
//  Created by Dexter Leng on 8/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import XCTest
@testable import Vimac

class TrieTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_contains_true() {
        let trie = Trie()
        
        XCTAssertFalse(
            trie.contains(Array("abc"))
        )
        
        trie.addWord(Array("abc"))
        
        XCTAssertTrue(
            trie.contains(Array("abc"))
        )
    }
    
    func test_contains_false() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertFalse(
            trie.contains(Array("ab"))
        )
    }
    
    func test_is_prefix_true() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertTrue(
            trie.isPrefix(Array("ab"))
        )
    }
    
    func test_is_prefix_true_when_equal() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertTrue(
            trie.isPrefix(Array("abc"))
        )
    }
    
    func test_is_prefix_false() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertFalse(
            trie.isPrefix(Array("x"))
        )
    }
    
    func test_is_prefix_true_when_empty_string() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertTrue(
            trie.isPrefix(Array(""))
        )
    }
    
    func test_is_prefix_false_when_longer() {
        let trie = Trie()
        
        trie.addWord(Array("abc"))
        
        XCTAssertFalse(
            trie.isPrefix(Array("abcd"))
        )
    }

}
