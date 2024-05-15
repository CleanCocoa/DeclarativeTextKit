//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class NSTextView_BufferTests: XCTestCase {
    func textView(_ string: String) -> NSTextView {
        let textView = NSTextView(usingTextLayoutManager: false)
        textView.string = string
        return textView
    }

    func testContent() {
        let string = "Test ⭐️ string 🚞 here"
        XCTAssertEqual(textView(string).content, string)
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
        let buffer = textView("hello")

        XCTAssertEqual(buffer.selectedRange, .init(location: buffer.range.upperBound, length: 0))

        buffer.select(.init(location: 2, length: 2))

        XCTAssertEqual(buffer.selectedRange, .init(location: 2, length: 2))
    }

    func testLineRange() {
        let buffer = textView("aa\nbb\ncc")

        // Individual lines
        XCTAssertEqual(buffer.lineRange(for: .init(location: 0, length: 0)), .init(location: 0, length: 3))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 3, length: 0)), .init(location: 3, length: 3))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 6, length: 0)), .init(location: 6, length: 2))

        // Wrapping lines
        XCTAssertEqual(buffer.lineRange(for: .init(location: 1, length: 3)), .init(location: 0, length: 6))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 4, length: 3)), .init(location: 3, length: 5))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 1, length: 7)), buffer.range)
    }

    func testDelete() {
        let buffer = textView("Lorem ipsum")

        buffer.delete(in: .init(location: 0, length: 3))
        buffer.delete(in: .init(location: 0, length: 3))

        XCTAssertEqual(buffer.content, "ipsum")
    }
}
