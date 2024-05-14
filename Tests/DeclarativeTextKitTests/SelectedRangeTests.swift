//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class SelectedRangeTests: XCTestCase {
    func testInit() {
        let range = SelectedRange(location: 10, length: 5)
        XCTAssertEqual(range.value, .init(location: 10, length: 5))
    }

    func testEquatable() {
        let value = Buffer.Range(location: 10, length: 5)
        XCTAssertEqual(SelectedRange(value), SelectedRange(value))
        XCTAssertNotEqual(SelectedRange(value), SelectedRange(location: 9, length: 5))
        XCTAssertNotEqual(SelectedRange(value), SelectedRange(location: 10, length: 4))
    }
}
