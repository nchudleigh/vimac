//
//  VimacTests.swift
//  VimacTests
//
//  Created by Dexter Leng on 17/9/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

import XCTest
@testable import Vimac

class VimacTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExampleA() {
        let e = expectation(description: "InputState calls listener with gg, when typing gg with < commonPrefixDelaySeconds in between")
        
        let keySequences: [[Character]] = [
            ["g"],
            ["g", "g"]
        ]
        let commonPrefixDelaySeconds: Double = 1.0
        let s = InputState(keySequences: keySequences, commonPrefixDelaySeconds: commonPrefixDelaySeconds)
        s.registerListener({ keySequence in
            XCTAssert(keySequence == ["g", "g"])
            e.fulfill()
        })
        XCTAssert(s.advance("g"))
        let _ = Timer.scheduledTimer(
            withTimeInterval: 0.8,
            repeats: false,
            block: { _ in
               XCTAssert(s.advance("g"))
            })
        
        waitForExpectations(timeout: 2.0, handler: { e in
            if let e = e {
                XCTFail("listener not alerted")
            }
        })
    }
    
    func testExampleB() {
        let e = expectation(description: "InputState calls listener with g, when typing gg with > commonPrefixDelaySeconds in between")
        
        let keySequences: [[Character]] = [
            ["g"],
            ["g", "g"]
        ]
        let commonPrefixDelaySeconds: Double = 1.0
        let s = InputState(keySequences: keySequences, commonPrefixDelaySeconds: commonPrefixDelaySeconds)
        s.registerListener({ keySequence in
            XCTAssert(keySequence == ["g"])
            e.fulfill()
        })
        XCTAssert(s.advance("g"))
        let _ = Timer.scheduledTimer(
            withTimeInterval: 1.1,
            repeats: false,
            block: { _ in
               XCTAssertFalse(s.advance("g"))
            })
        
        waitForExpectations(timeout: 2.0, handler: { e in
            if let e = e {
                XCTFail("listener not alerted")
            }
        })
    }
    
    func testExampleC() {
        let e = expectation(description: "listener called")
        
        let keySequences: [[Character]] = [
            ["g"],
            ["g", "g"]
        ]
        let commonPrefixDelaySeconds: Double = 1.0
        let s = InputState(keySequences: keySequences, commonPrefixDelaySeconds: commonPrefixDelaySeconds)
        s.registerListener({ keySequence in
            e.fulfill()
        })
        XCTAssert(s.advance("g"))
        XCTAssertFalse(s.advance("a"))
        
        waitForExpectations(timeout: 1.0, handler: { e in
            if let e = e {
                XCTFail("listener not alerted")
            }
        })
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
