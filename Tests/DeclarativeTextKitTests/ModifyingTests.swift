//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class ModifyingTests: XCTestCase {
    func testModifying_InsertionAtBothEnds() throws {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum.")
        let selectedRange: SelectedRange = .init(location: 6, length: 5)

        let modify = Modifying(selectedRange) { affectedRange in
            Insert(affectedRange.location) { "de" }
            Insert(affectedRange.endLocation) { "esque" }
        }

        XCTAssertEqual(selectedRange, .init(location: 6, length: 5),
                       "SelectedRange box is unchanged before evaluation")
        assertBufferState(buffer, "{^}Lorem ipsum.",
                          "Content and selection is unchanged before evaluation")

        try modify.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Lorem deipsumesque.")
        XCTAssertEqual(selectedRange, .init(location: 6, length: 12))
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

        try modify.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Lipsum.")
        XCTAssertEqual(fullRange, .init(location: 0, length: 7))
    }
}
