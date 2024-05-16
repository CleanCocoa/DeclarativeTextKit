//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class ModifyingTests: XCTestCase {
    func testModifying_InsertionAtBothEnds() {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum.")
        let selectedRange: SelectedRange = .init(location: 6, length: 5)

        var modify = Modifying(selectedRange) { affectedRange in
            Insert(affectedRange.location) { "de" }
            Insert(affectedRange.endLocation) { "esque" }
        }
        modify.callAsFunction(buffer: buffer)

        XCTAssertEqual(buffer.content, "Lorem deipsumesque.")
        XCTAssertEqual(selectedRange, .init(location: 6, length: 12))
    }

    func testModifying_DeletingMultiplePlaces() {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum dolor sit.")
        let fullRange = SelectedRange(buffer.range)

        var modify = Modifying(fullRange) { range in
            Delete(.init(location: range.location + 1, length: length(of: "orem ")))
            Delete(11 ..< range.endLocation - 1)
        }
        modify.callAsFunction(buffer: buffer)

        XCTAssertEqual(buffer.content, "Lipsum.")
        XCTAssertEqual(fullRange, .init(location: 0, length: 7))
    }
}
