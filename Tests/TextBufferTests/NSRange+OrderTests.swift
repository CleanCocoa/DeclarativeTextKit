//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSRange_OrderTests: XCTestCase {
    let referenceRange = NSRange(location: 10, length: 5)

    func testOrdering() {
        XCTAssertEqual(NSRange(location: 0, length: 0).ordered(comparedTo: referenceRange), .strictlyBefore)
        XCTAssertEqual(NSRange(location: 0, length: 10).ordered(comparedTo: referenceRange), .strictlyBefore)
        XCTAssertEqual(NSRange(location: 9, length: 0).ordered(comparedTo: referenceRange), .strictlyBefore)
        XCTAssertEqual(NSRange(location: 9, length: 1).ordered(comparedTo: referenceRange), .strictlyBefore)
        XCTAssertEqual(NSRange(location: 10, length: 0).ordered(comparedTo: referenceRange), .strictlyBefore)

        XCTAssertEqual(NSRange(location: 10, length: 1).ordered(comparedTo: referenceRange), .intersects)
        XCTAssertEqual(NSRange(location: 0, length: 20).ordered(comparedTo: referenceRange), .intersects)
        XCTAssertEqual(NSRange(location: 0, length: 100).ordered(comparedTo: referenceRange), .intersects)
        XCTAssertEqual(NSRange(location: 14, length: 20).ordered(comparedTo: referenceRange), .intersects)
        XCTAssertEqual(NSRange(location: 14, length: 1).ordered(comparedTo: referenceRange), .intersects)
        XCTAssertEqual(NSRange(location: 14, length: 0).ordered(comparedTo: referenceRange), .intersects)

        XCTAssertEqual(NSRange(location: 15, length: 1).ordered(comparedTo: referenceRange), .strictlyAfter)
        XCTAssertEqual(NSRange(location: 15, length: 0).ordered(comparedTo: referenceRange), .strictlyAfter)
        XCTAssertEqual(NSRange(location: 15, length: 10).ordered(comparedTo: referenceRange), .strictlyAfter)
        XCTAssertEqual(NSRange(location: 16, length: 20).ordered(comparedTo: referenceRange), .strictlyAfter)

        // 1...1 is just the 1st character location, doesn't cover the 2nd
        XCTAssertEqual(NSRange(location: 1, length: 0).ordered(comparedTo: NSRange(location: 2, length: 0)), .strictlyBefore)
        XCTAssertEqual(NSRange(location: 1, length: 1).ordered(comparedTo: NSRange(location: 2, length: 0)), .strictlyBefore)
    }
}
