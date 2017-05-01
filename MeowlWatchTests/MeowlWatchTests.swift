//
//  MeowlWatchTests.swift
//  MeowlWatchTests
//
//  Created by Jonathan Chan on 2017-04-27.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import XCTest
@testable import MeowlWatchData

class MeowlWatchDataTests: XCTestCase {
    
    func testDiningHallSessionRead() {
        XCTAssertEqual(diningSession(for: .allison, at: Date(timeIntervalSince1970: 1493335609)), .dinner)
    }

    
    
}
