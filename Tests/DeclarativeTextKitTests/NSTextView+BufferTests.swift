//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class NSTextView_BufferTests: XCTestCase {
    func testContent() {
        let string = "Test ⭐️ string 🚞 here"
        let buffer = textView(string)
        XCTAssertEqual(buffer.content, string)
        assertBufferState(buffer, "Test ⭐️ string 🚞 here{^}",
                          "NSTextView puts insertion point at end of buffer")
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

    func testUnsafeCharacterAtLocation() {
        let buffer = textView("bug 🐞")
        let characters = (0..<5).map { buffer.unsafeCharacter(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testCharacterAtLocation() throws {
        let buffer = textView("bug 🐞")
        let characters = try (0..<5).map { try buffer.character(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testCharacterAtLocation_OutOfBounds() throws {
        let buffer = textView("hi")
        assertThrows(
            try buffer.character(at: 2),
            error: LocationOutOfBounds(location: 2, bounds: .init(location: 0, length: 2))
        )
    }

    func testInsertContentAtLocation() throws {
        let buffer = textView("hi")
        buffer.insertionLocation = 1

        assertBufferState(buffer, "h{^}i")

        try buffer.insert("🐞 bug", at: 1)

        assertBufferState(buffer, "h🐞 bug{^}i")
    }

    func testInsertOverSelection() {
        let buffer = textView("fizz buzz fizz buzz")
        let selectedRange = Buffer.Range(location: 5, length: 5)
        buffer.select(selectedRange)

        assertBufferState(buffer, "fizz {buzz }fizz buzz")

        buffer.insert("")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz {^}fizz buzz")

        buffer.insert("foo ")
        assertBufferState(buffer, "fizz foo {^}fizz buzz")
    }

    func testInsertOutOfBounds() {
        let buffer = textView("hi")
        assertThrows(
            try buffer.insert("💣", at: 3),
            error: LocationOutOfBounds(
                location: 3,
                bounds: .init(location: 0, length: 2))
        )
    }

    func testSelect() {
        let buffer = textView("hello")

        XCTAssertFalse(buffer.isSelectingText)
        XCTAssertEqual(buffer.selectedRange, .init(location: buffer.range.upperBound, length: 0))

        buffer.select(.init(location: 2, length: 2))

        XCTAssertTrue(buffer.isSelectingText)
        XCTAssertEqual(buffer.selectedRange, .init(location: 2, length: 2))
        XCTAssertEqual(buffer.insertionLocation, 2)
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
        buffer.insertionLocation = 5

        assertBufferState(buffer, "Lorem{^} ipsum")

        buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "em{^} ipsum")

        buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "{^}ipsum")
    }

    func testReplaceAroundInsertionPoint() {
        let buffer: Buffer = textView("Goodbye, cruel world!")
        buffer.insertionLocation = length(of: "Goodbye, cruel")

        assertBufferState(buffer, "Goodbye, cruel{^} world!")

        buffer.replace(range: .init(location: 9, length: 6), with: "")
        assertBufferState(buffer, "Goodbye, {^}world!")

        buffer.replace(range: .init(location: 0, length: 7), with: "Hello")
        assertBufferState(buffer, "Hello, {^}world!")
    }

    func testReplaceInSelectedRange() {
        let buffer: Buffer = textView("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor{em ip}sum")

        buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x{ip}sum")

        buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "y{^}um")
    }
}
