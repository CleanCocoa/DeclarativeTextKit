//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class ScopedBufferSliceTests: XCTestCase {
    let availableRange = Buffer.Range(location: 3, length: 3)

    func createScopedBufferSlice() -> ScopedBufferSlice<MutableStringBuffer> {
        let base = MutableStringBuffer("0123456789")
        let scopedSlice = try! ScopedBufferSlice(base: base, scopedRange: availableRange)
        return scopedSlice
    }

    func testInit_RangeInBounds() throws {
        let buffer = textView("abc")
        buffer.insertionLocation = 1

        let scopedSlice = try ScopedBufferSlice(base: buffer, scopedRange: .init(location: 1, length: 2))

        assertBufferState(scopedSlice, "a{^}bc")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 1, length: 2))
    }

    func testInit_RangeOutOfBounds_Throws() {
        let buffer = textView("abc")

        assertThrows(
            try ScopedBufferSlice(base: buffer, scopedRange: .init(location: 3, length: 2)),
            error: BufferAccessFailure.outOfRange(
                location: 3, length: 2,
                available: .init(location: 0, length: 3)
            )
        )
    }

    func testCharacterAtLocation() throws {
        let scopedSlice = createScopedBufferSlice()

        for locationOutOfBounds in Array(0..<3) + Array(6..<10) {
            assertThrows(
                try scopedSlice.character(at: locationOutOfBounds),
                error: BufferAccessFailure.outOfRange(
                    location: locationOutOfBounds, length: 1,
                    available: availableRange
                )
            )
        }

        for locationInBounds in 3..<6 {
            XCTAssertNoThrow(try scopedSlice.character(at: locationInBounds))
        }
    }

    func testInsert_OutOfBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        for locationOutOfBounds in Array(0..<3) + Array(7..<10) {
            assertThrows(
                try scopedSlice.insert("💣", at: locationOutOfBounds),
                error: BufferAccessFailure.outOfRange(
                    location: locationOutOfBounds, length: 0,
                    available: availableRange
                )
            )
        }
    }

    func testInsert_InsideBounds() throws {
        for locationInBounds in 3...6 {
            // Reset content for each test because the buffer is modified
            let scopedSlice = createScopedBufferSlice()

            // Precondition
            XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 3))

            XCTAssertNoThrow(try scopedSlice.insert("xxx", at: locationInBounds))
            
            // Postcondition
            XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 6), "Insertion should expand range")
        }
    }

    func testDelete_OutOfBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        for locationOutOfBounds in Array(-1..<3) + Array(6..<12) {
            for length in (0...2) {
                let range = Buffer.Range(location: locationOutOfBounds, length: length)
                assertThrows(
                    try scopedSlice.delete(in: range),
                    error: BufferAccessFailure.outOfRange(
                        requested: range,
                        available: availableRange
                    )
                )
            }
        }

        let rangesOutOfBounds: [Buffer.Range] = [
            .init(location: 1, length: 8),
            .init(location: 2, length: 4),
            .init(location: 4, length: 4),
        ]
        for rangesOutOfBound in rangesOutOfBounds {
            assertThrows(
                try scopedSlice.delete(in: rangesOutOfBound),
                error: BufferAccessFailure.outOfRange(
                    requested: rangesOutOfBound,
                    available: availableRange
                )
            )
        }
    }

    func testDelete_InsideBounds() throws {
        for locationInBounds in 3..<6 {
            // Reset content for each test because the buffer is modified
            let scopedSlice = createScopedBufferSlice()

            for length in (0...1) {
                // Precondition
                XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 3))

                XCTAssertNoThrow(try scopedSlice.delete(in: .init(location: locationInBounds, length: length)))

                // Postcondition
                XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 3 - length), "Deletion should shrink range")
            }
        }
    }

    func testReplace_OutOfBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        for locationOutOfBounds in Array(-1..<3) + Array(6..<12) {
            for length in (0...2) {
                let range = Buffer.Range(location: locationOutOfBounds, length: length)
                assertThrows(
                    try scopedSlice.replace(range: range, with: "something"),
                    error: BufferAccessFailure.outOfRange(
                        requested: range,
                        available: availableRange
                    )
                )
            }
        }
    }

    func testReplace_InsideBounds() throws {
        for locationInBounds in 3..<6 {
            // Reset content for each test because the buffer is modified
            let scopedSlice = createScopedBufferSlice()

            for length in (0...1) {
                XCTAssertNoThrow(try scopedSlice.replace(range: .init(location: locationInBounds, length: length), with: "x"))
            }
        }
    }

    func testReplace_InsideBounds_ExpandsAvailableRange() throws {
        let scopedSlice = createScopedBufferSlice()

        // Precondition: {6,1} is out of range at first
        assertThrows(
            try scopedSlice.replace(range: .init(location: 6, length: 1), with: "x"),
            error: BufferAccessFailure.outOfRange(
                requested: .init(location: 6, length: 1),
                available: availableRange
            )
        )

        assertBufferState(scopedSlice, "{^}0123456789")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 3))

        try scopedSlice.replace(range: availableRange, with: "longness")
        assertBufferState(scopedSlice, "{^}012longness6789")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 8))

        try scopedSlice.replace(range: .init(location: 6, length: 2), with: "gestn")
        assertBufferState(scopedSlice, "{^}012longestness6789")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 11))
    }
}
