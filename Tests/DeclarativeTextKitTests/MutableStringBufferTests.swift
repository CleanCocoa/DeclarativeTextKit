//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class MutableStringBufferTests: XCTestCase {
    func testContent() {
        let string = "Test ⭐️ string 🚞 here"
        XCTAssertEqual(MutableStringBuffer(string).content, string)
    }

    func testRange() {
        XCTAssertEqual(MutableStringBuffer("").range,
                       .init(location: 0, length: 0))
        XCTAssertEqual(MutableStringBuffer("a").range,
                       .init(location: 0, length: 1))
        XCTAssertEqual(MutableStringBuffer("hello\n\nworld").range,
                       .init(location: 0, length: 12))
        XCTAssertEqual(MutableStringBuffer("💃🐞🏴‍☠️").range,
                       .init(location: 0, length: 9))
    }

    func testCharacterAtLocation() {
        let buffer = MutableStringBuffer("bug 🐞")
        let characters = (0..<5).map { buffer.unsafeCharacter(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testInsertContentAtLocation() {
        let buffer = MutableStringBuffer("hi")

        buffer.insert("🐞 bug", at: 1)

        XCTAssertEqual(buffer, "h🐞 bugi")
    }

    func testInsertOverSelection() {
        let buffer = MutableStringBuffer("fizz buzz fizz buzz")

        let selectedRange = Buffer.Range(location: 5, length: 5)
        buffer.select(selectedRange)

        XCTAssertTrue(buffer.isSelectingText)
        XCTAssertEqual(buffer.description, "fizz {buzz }fizz buzz")

        buffer.insert("")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        XCTAssertEqual(buffer.description, "fizz {^}fizz buzz")

        buffer.insert("foo ")
        XCTAssertEqual(buffer.description, "fizz foo {^}fizz buzz")
    }

    func testSelectedRange() {
        let buffer = MutableStringBuffer("hi")

        // Precondition
        XCTAssertEqual(buffer.selectedRange, .init(location: 0, length: 0))

        buffer.select(.init(location: 1, length: 1))

        // Postcondition
        XCTAssertEqual(buffer.selectedRange, .init(location: 1, length: 1))
    }

    func testLineRange() {
        let buffer = MutableStringBuffer("aa\nbb\ncc")

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
        let buffer = MutableStringBuffer("Hello: world!")

        buffer.delete(in: .init(location: 0, length: 4))
        buffer.delete(in: .init(location: 0, length: 4))

        XCTAssertEqual(buffer.description, "{^}orld!")
    }

    func testReplace() {
        let buffer = MutableStringBuffer("Goodbye, cruel world!")

        buffer.replace(range: .init(location: 9, length: 6), with: "")
        buffer.replace(range: .init(location: 0, length: 7), with: "Hello")

        XCTAssertEqual(buffer.description, "Hello{^}, world!")
    }
}
