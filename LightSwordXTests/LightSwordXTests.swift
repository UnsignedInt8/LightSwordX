//
//  LightSwordXTests.swift
//  LightSwordXTests
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import XCTest
@testable import LightSwordX

class LightSwordXTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testIpv4() {
        let rawData = [0x87, 0x58, 0x24, 0xef];
        let addr = rawData.reduce("", combine: { (c: String, n: Int) in c.characters.count > 1 ? c + String(format: ".%d", n) : String(format: "%d.%d", c, n)})
        
        assert(addr == "135.88.36.239");
    }
    
}
