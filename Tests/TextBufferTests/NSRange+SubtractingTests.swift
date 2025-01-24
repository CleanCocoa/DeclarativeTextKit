//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSRange_SubtractingTests: XCTestCase {
    var referenceRange = NSRange(location: 100, length: 100)

    func subtracting(location: Int, length: Int) -> NSRange {
        referenceRange.subtracting(NSRange(location: location, length: length))
    }

    func testRange_Subtracting_After_DoesntChangeRange() {
        XCTAssertEqual(
            subtracting(location: 200, length: 999),
            referenceRange,
            "Subtracting range that is chiefly *after* doesn't change receiver"
        )
    }

    func testRange_Subtracting_NSNotFound_DoesntChangeRange() {
        XCTAssertEqual(subtracting(location: NSNotFound, length: 0), referenceRange)
        XCTAssertEqual(subtracting(location: NSNotFound, length: Int.min), referenceRange)
        XCTAssertEqual(subtracting(location: NSNotFound, length: Int.max), referenceRange)
    }

    func testRange_Subtracting_FromNSNotFound_ReturnsNSNotFound() {
        let ranges: [NSRange] = [
            .init(location: 1, length: Int.max),
            .init(location: 0, length: Int.max),
            .init(location: -10, length: 20),
            .init(location: -1, length: 1),
            .init(location: -2, length: 2),
            .init(location: Int.min, length: Int.max),
            .init(location: Int.min, length: Int.max),
        ]
        for range in ranges {
            XCTAssertEqual(NSRange.notFound.subtracting(range), .notFound)
        }
    }

    func testRange_Subtracting_Before_MovesRangeLeftward() {
        XCTAssertEqual(
            subtracting(location: 0, length: 50),
            NSRange(location: 50, length: 100),
            "Subtracting a range wholly contained before reference range nudges it towards the 0 position"
        )

        XCTAssertEqual(
            subtracting(location: 99, length: 1),
            NSRange(location: 99, length: 100),
            "Subtracting a range wholly contained before reference range nudges it towards the 0 position"
        )

        XCTAssertEqual(
            subtracting(location: 0, length: 0),
            referenceRange,
            "Subtracting empty range is a no-op"
        )
        XCTAssertEqual(
            subtracting(location: 99, length: 0),
            referenceRange,
            "Subtracting empty range is a no-op"
        )
    }

    func testRange_Subtracting_OverlappingAtStart() {
        XCTAssertEqual(
            subtracting(location: 90, length: 20),
            NSRange(location: 90, length: 100 - 10)
        )

        XCTAssertEqual(
            subtracting(location: 100, length: 20),
            NSRange(location: 100, length: 100 - 20)
        )

        XCTAssertEqual(
            subtracting(location: 0, length: 199),
            NSRange(location: 0, length: 100 - 99)
        )

        XCTAssertEqual(
            subtracting(location: 0, length: 999),
            NSRange(location: 0, length: 0)
        )
    }

    func testRange_Subtracting_OverlappingAtEnd() {
        XCTAssertEqual(
            subtracting(location: 190, length: 20),
            NSRange(location: 100, length: 100 - 10)
        )

        XCTAssertEqual(
            subtracting(location: 100, length: 99),
            NSRange(location: 100, length: 100 - 99)
        )

        XCTAssertEqual(
            subtracting(location: 100, length: 999),
            NSRange(location: 100, length: 0)
        )

        XCTAssertEqual(
            subtracting(location: 50, length: 999),
            NSRange(location: 50, length: 0)
        )
    }

    func testRange_Subtracting_ContainedInside() {
        XCTAssertEqual(
            subtracting(location: 50, length: 0),
            referenceRange
        )
        XCTAssertEqual(
            subtracting(location: 199, length: 0),
            referenceRange
        )
        XCTAssertEqual(
            subtracting(location: 100, length: 0),
            referenceRange
        )

        XCTAssertEqual(
            subtracting(location: 100, length: 1),
            NSRange(location: 100, length: 100 - 1)
        )
        XCTAssertEqual(
            subtracting(location: 199, length: 1),
            NSRange(location: 100, length: 100 - 1)
        )

        XCTAssertEqual(
            subtracting(location: 150, length: 20),
            NSRange(location: 100, length: 100 - 20)
        )

        XCTAssertEqual(
            subtracting(location: 101, length: 98),
            NSRange(location: 100, length: 100 - 98)
        )

        XCTAssertEqual(
            subtracting(location: 100, length: 100),
            NSRange(location: 100, length: 0)
        )
    }

    func testRange_Subtracting_PathologicalCases() {
        XCTAssertEqual(
            subtracting(location: -999, length: 9999999),
            NSRange(location: 0, length: 0)
        )

        XCTAssertEqual(
            subtracting(location: 200, length: -999),
            referenceRange,
            "Starting at the end and removing 'backwards' with negative length is undefined"
        )

        XCTAssertNotEqual(
            subtracting(location: 150, length: -100),
            referenceRange,
            "Starting in the middle and removing 'backwards' with negative length is undefined"
        )
    }
}
