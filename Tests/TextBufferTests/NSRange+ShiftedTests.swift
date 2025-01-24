//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSRange_ShiftedTests: XCTestCase {
    var referenceRange = NSRange(location: 100, length: 100)

    func shifted(by delta: Int) -> NSRange {
        referenceRange.shifted(by: delta)
    }

    func testOffset_NeutralElement() {
        XCTAssertEqual(shifted(by: 0), referenceRange)
    }

    func testOffset_Right() {
        XCTAssertEqual(shifted(by: 1), NSRange(location: 101, length: 100))
        XCTAssertEqual(shifted(by: 1000), NSRange(location: 1100, length: 100))
    }

    func testOffset_Left() {
        XCTAssertEqual(shifted(by: -1), NSRange(location: 99, length: 100))
        XCTAssertEqual(shifted(by: -50), NSRange(location: 50, length: 100))
        XCTAssertEqual(shifted(by: -100), NSRange(location: 0, length: 100))
    }

    func testOffset_Left_BelowZero() {
        XCTAssertEqual(shifted(by: -130), NSRange(location: 0, length: 100 - 30))
        XCTAssertEqual(shifted(by: -199), NSRange(location: 0, length: 1))
        XCTAssertEqual(shifted(by: -200), NSRange(location: 0, length: 0))
        XCTAssertEqual(shifted(by: -999), NSRange(location: 0, length: 0))
    }
}
