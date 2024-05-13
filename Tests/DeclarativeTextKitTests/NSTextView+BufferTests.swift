//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class NSTextView_BufferTests: XCTestCase {
    func textView(_ string: String) -> NSTextView {
        let textView = NSTextView(usingTextLayoutManager: false)
        textView.string = string
        return textView
    }

    func testRange() {
        XCTAssertEqual(textView("").range,
                       .init(location: 0, length: 0))
        XCTAssertEqual(textView("a").range,
                       .init(location: 0, length: 1))
        XCTAssertEqual(textView("hello\n\nworld").range,
                       .init(location: 0, length: 12))
        XCTAssertEqual(textView("💃🐞🏴‍☠️").range,
                       .init(location: 0, length: 9))
    }

    func testCharacterAtLocation() {
        let buffer = textView("bug 🐞")
        let characters = (0..<5).map { buffer.unsafeCharacter(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testInsertContentAtLocation() {
        let buffer = textView("hi")

        buffer.insert("🐞 bug", at: 1)

        XCTAssertEqual(buffer.string, "h🐞 bugi")
    }

    func testSelect() {
        let sut = textView("hello")

        sut.select(.init(location: 2, length: 2))

        XCTAssertEqual(sut.selectedRange, .init(location: 2, length: 2))
    }
}
