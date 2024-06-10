//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class ScopedBufferSliceTests: XCTestCase {
    let availableRange = Buffer.Range(location: 3, length: 3)

    func createScopedBufferSlice() -> ScopedBufferSlice<MutableStringBuffer> {
        let base = try! makeBuffer("01234567ˇ89")
        let scopedSlice = try! ScopedBufferSlice(base: base, scopedRange: availableRange)
        return scopedSlice
    }

    func testInit_RangeInBounds() throws {
        let buffer = MutableStringBuffer("abc")
        buffer.insertionLocation = 1

        let allRangesInBounds: [Buffer.Range] = [
            .init(location: 0, length: 0),
            .init(location: 0, length: 1),
            .init(location: 0, length: 2),
            .init(location: 0, length: 3),
            .init(location: 1, length: 0),
            .init(location: 1, length: 1),
            .init(location: 1, length: 2),
            .init(location: 2, length: 0),
            .init(location: 2, length: 1),
            .init(location: 3, length: 0),
        ]
        for rangeInBounds in allRangesInBounds {
            let scopedSlice = try ScopedBufferSlice(base: buffer, scopedRange: rangeInBounds)

            assertBufferState(scopedSlice, "aˇbc")
            XCTAssertEqual(scopedSlice.scopedRange, rangeInBounds)
            XCTAssertEqual(scopedSlice.range, rangeInBounds,
                           "Reports the scoped range to be all there is")
        }
    }

    func testInit_Appending() throws {
        let baseBuffer = try makeBuffer("aˇbc")
        let scopedSlice = try ScopedBufferSlice.appending(to: baseBuffer)

        assertBufferState(scopedSlice, "aˇbc")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 0))
    }

    func testInit_RangeOutOfBounds_Throws() {
        let buffer = MutableStringBuffer("abc")

        assertThrows(
            try ScopedBufferSlice(base: buffer, scopedRange: .init(location: 3, length: 2)),
            error: BufferAccessFailure.outOfRange(
                location: 3, length: 2,
                available: .init(location: 0, length: 3)
            )
        )
    }

    func testWordRange_OutsideBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        let rangesOutOfBounds: [Buffer.Range] = [
            .init(location: 1, length: 8),
            .init(location: 2, length: 4),
            .init(location: 4, length: 4),
        ]
        for rangeOutOfBound in rangesOutOfBounds {
            assertThrows(
                try scopedSlice.wordRange(for: rangeOutOfBound),
                error: BufferAccessFailure.outOfRange(
                    requested: rangeOutOfBound,
                    available: availableRange
                )
            )
        }
    }

    func testWordRange_InsideBounds() throws {
        let baseBuffer = try makeBuffer("foo b«ar»f baz")
        let scopedSlice = try ScopedBufferSlice(base: baseBuffer, scopedRange: baseBuffer.selectedRange)

        let expectedWordRange = Buffer.Range(
            location: length(of: "foo "),
            length: length(of: "barf")
        )
        for locationInBounds in (scopedSlice.scopedRange.location ..< scopedSlice.scopedRange.endLocation) {
            let searchRange = Buffer.Range(location: locationInBounds, length: 0)
            XCTAssertEqual(try scopedSlice.wordRange(for: searchRange), expectedWordRange,
                           "Range finding may extend beyond scope for action chaining")
        }
    }

    func testLineRange_OutsideBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        let rangesOutOfBounds: [Buffer.Range] = [
            .init(location: 1, length: 8),
            .init(location: 2, length: 4),
            .init(location: 4, length: 4),
        ]
        for rangeOutOfBound in rangesOutOfBounds {
            assertThrows(
                try scopedSlice.lineRange(for: rangeOutOfBound),
                error: BufferAccessFailure.outOfRange(
                    requested: rangeOutOfBound,
                    available: availableRange
                )
            )
        }
    }

    func testLineRange_InsideBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        let expectedLineRange = Buffer.Range(location: 0, length: 10)
        for locationInBounds in (availableRange.location ... availableRange.endLocation) {
            let searchRange = Buffer.Range(location: locationInBounds, length: 0)
            let lineRange = try scopedSlice.lineRange(for: searchRange)
            XCTAssertEqual(lineRange, expectedLineRange,
                           "Range finding may extend beyond scope for action chaining")
        }
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

    func testContentInRange() throws {
        let scopedSlice = createScopedBufferSlice()

        let characterPairs = try (3..<5).map { try scopedSlice.content(in: .init(location: $0, length: 2)) }
        XCTAssertEqual(characterPairs, ["34", "45"])

        XCTAssertEqual(try scopedSlice.content(in: availableRange), "345")
    }

    func testContentInRange_OutOfBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        for locationOutOfBounds in Array(-1..<3) + Array(7..<12) {
            for length in (0...2) {
                let range = Buffer.Range(location: locationOutOfBounds, length: length)
                assertThrows(
                    try scopedSlice.content(in: range),
                    error: BufferAccessFailure.outOfRange(
                        requested: range,
                        available: availableRange
                    ),
                    "Reading from \(range)"
                )
            }
        }
    }

    func testContentInRange_AtEndLocation() throws {
        let scopedSlice = createScopedBufferSlice()

        XCTAssertEqual(try scopedSlice.content(in: .init(location: 6, length: 0)), "",
                       "Reading 0 length substring at endLocation should ")

        for length in (1...2) {
            let range = Buffer.Range(location: 6, length: length)
            assertThrows(
                try scopedSlice.content(in: range),
                error: BufferAccessFailure.outOfRange(
                    requested: range,
                    available: availableRange
                ),
                "Reading from \(range)"
            )
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

    func testInsert_Appending() throws {
        let base = MutableStringBuffer("0123456789")
        base.insertionLocation = 10
        let scopedSlice = try ScopedBufferSlice(base: base, scopedRange: .init(location: 7, length: 3))

        assertBufferState(scopedSlice, "0123456789ˇ")

        XCTAssertNoThrow(try scopedSlice.insert("xxx"))

        // Postcondition
        assertBufferState(scopedSlice, "0123456789xxxˇ")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 7, length: 6), "Insertion should expand range")
    }

    func testDelete_OutOfBounds() throws {
        let scopedSlice = createScopedBufferSlice()

        XCTAssertEqual(try scopedSlice.content(in: .init(location: 6, length: 0)), "",
                       "Reading 0 length substring at endLocation should ")
        for length in (1...2) {
            let range = Buffer.Range(location: 6, length: length)
            assertThrows(
                try scopedSlice.content(in: range),
                error: BufferAccessFailure.outOfRange(
                    requested: range,
                    available: availableRange
                ),
                "Reading from \(range)"
            )
        }

        for locationOutOfBounds in Array(-1..<3) + Array(7..<12) {
            for length in (0...2) {
                let range = Buffer.Range(location: locationOutOfBounds, length: length)
                assertThrows(
                    try scopedSlice.delete(in: range),
                    error: BufferAccessFailure.outOfRange(
                        requested: range,
                        available: availableRange
                    ),
                    "Deleting in \(range)"
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

        for locationOutOfBounds in Array(-1..<3) + Array(7..<12) {
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
            for length in 0...1 {
                // Reset content for each test because the buffer is modified
                let scopedSlice = createScopedBufferSlice()

                XCTAssertNoThrow(try scopedSlice.replace(range: .init(location: locationInBounds, length: length), with: "x"))
            }
        }
    }

    func testReplace_AtEdgeOfBoundsBounds() throws {
        // Replacing at the endLocation with 0 length is like typing/inserting/appending.
        XCTAssertNoThrow(
            try createScopedBufferSlice().replace(range: .init(location: 6, length: 0), with: "x"),
            "Typing at endLocation is permitted")
        XCTAssertNoThrow(
            try createScopedBufferSlice().replace(range: .init(location: 6, length: 0), with: "xyz"),
            "Length of inserted text doesn't matter")

        // Replacing a character beyond the bounds should throw
        assertThrows(
            try createScopedBufferSlice().replace(range: .init(location: 6, length: 1), with: "x"),
            error: BufferAccessFailure.outOfRange(
                requested: .init(location: 6, length: 1),
                available: availableRange))
        // Deleting a character beyond the bounds should throw
        assertThrows(
            try createScopedBufferSlice().replace(range: .init(location: 6, length: 1), with: ""),
            error: BufferAccessFailure.outOfRange(
                requested: .init(location: 6, length: 1),
                available: availableRange))
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

        assertBufferState(scopedSlice, "01234567ˇ89")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 3))

        try scopedSlice.replace(range: availableRange, with: "longness")
        assertBufferState(scopedSlice, "012longness67ˇ89")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 8))

        try scopedSlice.replace(range: .init(location: 6, length: 2), with: "gestn")
        assertBufferState(scopedSlice, "012longestness67ˇ89")
        XCTAssertEqual(scopedSlice.scopedRange, .init(location: 3, length: 11))
    }
}

extension ScopedBufferSliceTests {
    func testExpandingSelectionRangeBeyondScope_ByWord() throws {
        let baseBuffer = try makeBuffer("foo ba«r fiz»z buzz")

        try baseBuffer.evaluate(in: baseBuffer.selectedRange) { affectedRange in
            Modifying(affectedRange) { scopedRange in
                Select(WordRange(scopedRange))
            }
        }

        assertBufferState(baseBuffer, "foo «bar fizz» buzz")
    }

    func testExpandingSelectionRangeBeyondScope_ByLine() throws {
        let baseBuffer = try makeBuffer("""
            first
            se«co»nd
            third
            """)

        try baseBuffer.evaluate(in: baseBuffer.selectedRange) { affectedRange in
            Modifying(affectedRange) { scopedRange in
                Select(LineRange(scopedRange))
            }
        }

        assertBufferState(baseBuffer, """
            first
            «second
            »third
            """)
    }

    func testModifying_DelegatesToBaseAndProtectsScope() throws {
        class Delegate: NSObject, NSTextViewDelegate {
            var shouldChangeText = false

            func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
                return shouldChangeText
            }
        }

        let buffer = textView("Text")
        let delegate = Delegate()
        buffer.textView.delegate = delegate
        let availableRange = Buffer.Range(location: 1, length: 2)
        let scopedSlice = try! ScopedBufferSlice(base: buffer, scopedRange: availableRange)

        let length = 1
        let locationsInScopeForEditing = 1...2
        let locationsOutOfScope = Array(0..<1) + Array(3..<4)

        // MARK: Forbidden
        delegate.shouldChangeText = false
        // Error outside of scope
        for location in locationsOutOfScope {
            let range = Buffer.Range(location: location, length: length)
            assertThrows(
                try scopedSlice.modifying(affectedRange: range) {
                    XCTFail("Modification in \(range) should not execute")
                },
                error: BufferAccessFailure.outOfRange(
                    requested: range,
                    available: availableRange
                )
            )
        }
        // Forbidden in scope
        for location in locationsInScopeForEditing {
            let range = Buffer.Range(location: location, length: length)
            assertThrows(
                try scopedSlice.modifying(affectedRange: range) {
                    XCTFail("Modification should not execute")
                },
                error: BufferAccessFailure.modificationForbidden(in: range)
            )
        }
        assertThrows(
            try scopedSlice.modifyingScope {
                XCTFail("Modification should not execute")
            },
            error: BufferAccessFailure.modificationForbidden(in: scopedSlice.scopedRange)
        )


        // MARK: Allowed
        delegate.shouldChangeText = true
        // Error outside of scope
        for location in locationsOutOfScope {
            let range = Buffer.Range(location: location, length: length)
            assertThrows(
                try scopedSlice.modifying(affectedRange: range) {
                    XCTFail("Modification in \(range) should not execute")
                },
                error: BufferAccessFailure.outOfRange(
                    requested: range,
                    available: availableRange
                )
            )
        }
        // Allowed in scope
        for location in locationsInScopeForEditing {
            var didModify = false
            let result = try scopedSlice.modifying(affectedRange: .init(location: location, length: length)) {
                defer { didModify = true }
                return location * 2
            }
            XCTAssertTrue(didModify)
            XCTAssertEqual(result, location * 2)
        }
        var didModifyScope = false
        let result = try scopedSlice.modifyingScope {
            defer { didModifyScope = true }
            return 1337
        }
        XCTAssertTrue(didModifyScope)
        XCTAssertEqual(result, 1337)
    }
}
