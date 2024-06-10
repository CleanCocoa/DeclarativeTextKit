//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

extension AffectedRange: Equatable {
    public static func == (lhs: AffectedRange, rhs: AffectedRange) -> Bool {
        #if DEBUG
        return lhs.value == rhs.value
        #else
        fatalError("if you hit this, you probably moved the equatability into production, which we want to avoid :)")
        #endif
    }
}

final class AffectedRangeTests: XCTestCase {
    func testInit() {
        let range = AffectedRange(location: 10, length: 5)
        XCTAssertEqual(range.value, .init(location: 10, length: 5))
    }

    func testEquatable() {
        let value = Buffer.Range(location: 10, length: 5)
        XCTAssertEqual(AffectedRange(value), AffectedRange(value))
        XCTAssertNotEqual(AffectedRange(value), AffectedRange(location: 9, length: 5))
        XCTAssertNotEqual(AffectedRange(value), AffectedRange(location: 10, length: 4))
    }
}
