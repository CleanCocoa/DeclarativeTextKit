//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSRange_ContainsTests: XCTestCase {

    func testContains_EmptyRange() {
        let emptyRange = NSRange(location: 0, length: 0)

        XCTAssertTrue(emptyRange.contains(emptyRange))
        XCTAssertFalse(emptyRange.contains(NSRange(location: 0, length: 1)))
        XCTAssertFalse(emptyRange.contains(NSRange(location: -1, length: 1)))
    }

    func testContains() {
        let range = NSRange(startLocation: 100, endLocation: 200)

        let rangesWithin = [
            NSRange(startLocation: 100, endLocation: 200),
            NSRange(startLocation: 101, endLocation: 200),
            NSRange(startLocation: 100, endLocation: 199),
            NSRange(startLocation: 101, endLocation: 199),
            NSRange(startLocation: 150, endLocation: 151),
            NSRange(startLocation: 199, endLocation: 200),
            // Empty ranges with locations inside
            NSRange(location: 100, length: 0),
            NSRange(location: 150, length: 0),
            NSRange(location: 199, length: 0),
            // At-end location
            NSRange(location: 200, length: 0),
        ]

        let rangesOutside = [
            // Edge cases
            NSRange(startLocation: 99, endLocation: 200),
            NSRange(startLocation: 99, endLocation: 100),
            NSRange(startLocation: 100, endLocation: 201),
            NSRange(startLocation: 200, endLocation: 201),
            // Wholly outside
            NSRange(startLocation: 10, endLocation: 20),
            NSRange(startLocation: 210, endLocation: 220),
            // Overlapping
            NSRange(startLocation: 90, endLocation: 110),
            NSRange(startLocation: 190, endLocation: 210),
        ]

        for otherRange in rangesWithin {
            XCTAssertTrue(range.contains(otherRange),
                          "\(range) should contain \(otherRange)")
        }

        for otherRange in rangesOutside {
            XCTAssertFalse(range.contains(otherRange),
                           "\(range) should not contain \(otherRange)")
        }
    }
}
