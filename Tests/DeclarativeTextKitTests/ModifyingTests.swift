//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class ModifyingTests: XCTestCase {
    func testModifying_InsertionOutsideSelectedBounds_Throws() throws {
        func insertCharacter(at location: UTF16Offset) throws -> ChangeInLength {
            let modification = Modifying(location: 3, length: 3) { _ in
                Insert(location) { "x" }
            }
            // Create new buffer for each iteration to discard mutations from previous runs.
            return try modification.evaluate(in: MutableStringBuffer("0123456789"))
        }

        for locationOutOfBounds in Array(0..<3) + Array(7..<10) {
            assertThrows(
                try insertCharacter(at: locationOutOfBounds),
                error: BufferAccessFailure.outOfRange(
                    location: locationOutOfBounds,
                    available: .init(location: 3, length: 3)
                )
            )
        }

        for locationInBounds in 3...6 {
            XCTAssertEqual(try insertCharacter(at: locationInBounds), 1)
        }
    }

    func testModifying_InsertionAtBothEnds() throws {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum.")
        buffer.insertionLocation = 8
        let selectedRange: SelectedRange = .init(location: 6, length: 5)

        let modify = Modifying(selectedRange) { affectedRange in
            Insert(affectedRange.location) { "de" }
            Insert(affectedRange.endLocation) { "esque" }
        }

        XCTAssertEqual(selectedRange, .init(location: 6, length: 5),
                       "SelectedRange box is unchanged before evaluation")
        assertBufferState(buffer, "Lorem ip{^}sum.",
                          "Content and selection is unchanged before evaluation")

        let changeInLength = try modify.evaluate(in: buffer)

        XCTAssertEqual(changeInLength, 7)
        assertBufferState(buffer, "Lorem deip{^}sumesque.")
        XCTAssertEqual(selectedRange, .init(location: 6, length: 12))
    }

    func testModifying_InsertingInLoop() throws {
        let buffer: Buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 6
        let fullRange = SelectedRange(buffer.range)

        let modify = Modifying(fullRange) { range in
            // Inserting at multiple locations verifies that we can treat locations as absolute without one insertion invalidating the next.
            for location in stride(from: 0, to: 10, by: 2) {
                Insert(location) { "x" }
            }
        }

        XCTAssertEqual(fullRange, .init(buffer.range),
                       "SelectedRange box is unchanged before evaluation")
        assertBufferState(buffer, "012345{^}6789",
                          "Content and selection is unchanged before evaluation")

        let changeInLength = try modify.evaluate(in: buffer)

        XCTAssertEqual(changeInLength, 5)
        XCTAssertEqual(fullRange, .init(location: 0, length: 15))
        assertBufferState(buffer, "x01x23x45x{^}67x89")
    }


    func testModifying_DeletingMultiplePlaces() throws {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum dolor sit.")
        let fullRange = SelectedRange(buffer.range)

        let modify = Modifying(fullRange) { range in
            Delete(location: range.location + 1, length: length(of: "orem "))
            Delete(11 ..< range.endLocation - 1)
        }

        XCTAssertEqual(fullRange, .init(buffer.range),
                       "SelectedRange box is unchanged before evaluation")
        assertBufferState(buffer, "{^}Lorem ipsum dolor sit.",
                          "Content and selection is unchanged before evaluation")

        let changeInLength = try modify.evaluate(in: buffer)

        XCTAssertEqual(changeInLength, -15)
        assertBufferState(buffer, "{^}Lipsum.")
        XCTAssertEqual(fullRange, .init(location: 0, length: 7))
    }

    func testModifying_DeletingInLoop() throws {
        let buffer: Buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 6
        let fullRange = SelectedRange(buffer.range)

        let modify = Modifying(fullRange) { range in
            // Deleting at locations [0,1,2,3,4] tests that we can treat locations as absolute without one deletion invalidating the next.
            for location in 0..<5 {
                Delete(location: location, length: 1)
            }
        }

        XCTAssertEqual(fullRange, .init(buffer.range),
                       "SelectedRange box is unchanged before evaluation")
        assertBufferState(buffer, "012345{^}6789",
                          "Content and selection is unchanged before evaluation")

        let changeInLength = try modify.evaluate(in: buffer)

        XCTAssertEqual(changeInLength, -5)
        XCTAssertEqual(fullRange, .init(location: 0, length: 5))
        assertBufferState(buffer, "5{^}6789")
    }

    func testModifying_ModificationForbidden() throws {
        class Delegate: NSObject, NSTextViewDelegate {
            var shouldChangeText = false

            func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
                return shouldChangeText
            }
        }

        let buffer = textView("Lorem ipsum.")
        let delegate = Delegate()
        buffer.textView.delegate = delegate
        let selectedRange: SelectedRange = .init(location: 6, length: 5)

        assertBufferState(buffer, "Lorem ipsum.{^}")

        let modify = Modifying(selectedRange) { affectedRange in
            Insert(affectedRange.location) { "de" }
            Insert(affectedRange.endLocation) { "esque" }
        }

        // Forbidden
        delegate.shouldChangeText = false
        assertThrows(        
            try modify.evaluate(in: buffer),
            error: BufferAccessFailure.modificationForbidden(in: .init(location: 6, length: 5))
        )

        // Allowed
        delegate.shouldChangeText = true
        let changeInLength = try modify.evaluate(in: buffer)
        XCTAssertEqual(changeInLength, 7)
        assertBufferState(buffer, "Lorem deipsumesque.{^}")
        XCTAssertEqual(selectedRange, .init(location: 6, length: 12))
    }
}
