//
//  InputStateTests.swift
//  VimacTests
//
//  Created by Dexter Leng on 8/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import XCTest
@testable import Vimac

class InputStateTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_add_key_sequence_returns_false_on_duplicate() {
        let inputState = InputState()
        XCTAssertTrue(
            try! inputState.addWord(Array("abc"))
        )
        XCTAssertFalse(
            try! inputState.addWord(Array("abc"))
        )
    }

    func test_add_key_sequence_returns_false_if_it_is_prefix_of_registered_seq() {
        let inputState = InputState()
        XCTAssertTrue(
            try! inputState.addWord(Array("abc"))
        )
        XCTAssertFalse(
            try! inputState.addWord(Array("ab"))
        )
    }

    func test_add_key_sequence_returns_false_if_prefix_is_already_registered() {
        let inputState = InputState()
        XCTAssertTrue(
            try! inputState.addWord(Array("ab"))
        )
        XCTAssertFalse(
            try! inputState.addWord(Array("abcd"))
        )
    }
    
    func test_add_key_sequence_returns_true_if_common_prefix_but_unambiguous_end() {
        let inputState = InputState()
        XCTAssertTrue(
            try! inputState.addWord(Array("gg"))
        )
        XCTAssertTrue(
            try! inputState.addWord(Array("gi"))
        )
    }
    
    func test_initialized_to_words_added_transition() {
        let inputState = InputState()
        XCTAssertEqual(
            inputState.state,
            .initialized
        )
        try! inputState.addWord(Array("abcd"))
        XCTAssertEqual(
            inputState.state,
            .wordsAdded
        )
    }
    
    func test_advancing_on_initialized_state() {
        let inputState = InputState()
        XCTAssertThrowsError(try inputState.advance("c")) { error in
            XCTAssertEqual(error as? InputState.StateMachineError, InputState.StateMachineError.invalidTransition)
        }
    }
    
    func test_deadend_transition() {
        let inputState = InputState()
        try! inputState.addWord(Array("abcd"))
        try! inputState.advance("c")
        XCTAssertEqual(
            inputState.state,
            .deadend
        )
    }
    
    func test_words_added_to_advancable_transition() {
        let inputState = InputState()
        try! inputState.addWord(Array("abcd"))
        XCTAssertEqual(
            inputState.state,
            .wordsAdded
        )
        try! inputState.advance("a")
        XCTAssertEqual(
            inputState.state,
            .advancable
        )
    }
    
    func test_match_transition() {
        let inputState = InputState()
        try! inputState.addWord(Array("abcd"))
        XCTAssertEqual(
            inputState.state,
            .wordsAdded
        )
        try! inputState.advance("a")
        XCTAssertEqual(
            inputState.state,
            .advancable
        )
        try! inputState.advance("b")
        XCTAssertEqual(
            inputState.state,
            .advancable
        )
        try! inputState.advance("c")
        XCTAssertEqual(
            inputState.state,
            .advancable
        )
        try! inputState.advance("d")
        XCTAssertEqual(
            inputState.state,
            .matched
        )
    }
    
    func test_matched_word() {
        let inputState = InputState()
        try! inputState.addWord(Array("a"))
        try! inputState.advance("a")
        XCTAssertEqual(
            inputState.state,
            .matched
        )
        XCTAssertEqual(
            try! inputState.matchedWord(),
            Array("a")
        )
    }
}
