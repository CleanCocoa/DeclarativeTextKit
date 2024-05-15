//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class ModifyingTests: XCTestCase {
    func testModifying_InsertionAtBothEnds() {
        let buffer: Buffer = NSMutableString("Lorem ipsum.")
        let selectedRange: SelectedRange = .init(location: 6, length: 5)

        var modify = Modifying(selectedRange) { affectedRange in
            Insert(affectedRange.location) { "de" }
            Insert(affectedRange.endLocation) { "esque" }
        }
        modify.callAsFunction(buffer: buffer)

        XCTAssertEqual(buffer.content, "Lorem deipsumesque.")
        XCTAssertEqual(selectedRange, .init(location: 6, length: 12))
    }
}
