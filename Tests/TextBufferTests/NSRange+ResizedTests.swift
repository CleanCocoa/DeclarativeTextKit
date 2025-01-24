//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSRange_ResizedTests: XCTestCase {
    var referenceRange = NSRange(location: 100, length: 100)

    func resized(by delta: Int) -> NSRange {
        referenceRange.resized(by: delta)
    }

    func testResized_NeutralElement() {
        XCTAssertEqual(resized(by: 0), referenceRange)
    }

    func testResized_Enlarge() {
        XCTAssertEqual(resized(by: 1), NSRange(location: 100, length: 101))
        XCTAssertEqual(resized(by: 100), NSRange(location: 100, length: 200))
    }

    func testResized_Shrink() {
        XCTAssertEqual(resized(by: -1), NSRange(location: 100, length: 99))
        XCTAssertEqual(resized(by: -50), NSRange(location: 100, length: 50))
        XCTAssertEqual(resized(by: -99), NSRange(location: 100, length: 1))
        XCTAssertEqual(resized(by: -100), NSRange(location: 100, length: 0))
        XCTAssertEqual(resized(by: -101), NSRange(location: 100, length: 0))
        XCTAssertEqual(resized(by: -9999), NSRange(location: 100, length: 0))
    }
}
