//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

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

    func testUnsafeCharacterAtLocation() {
        let buffer = MutableStringBuffer("bug 🐞")
        let characters = (0..<5).map { buffer.unsafeCharacter(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testCharacterAtLocation() throws {
        let buffer = MutableStringBuffer("bug 🐞")
        let characters = try (0..<5).map { try buffer.character(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testCharacterAtLocation_OutOfBounds() throws {
        let buffer = MutableStringBuffer("hi")
        assertThrows(
            try buffer.character(at: 2),
            error: BufferAccessFailure.outOfRange(
                location: 2,
                available: .init(location: 0, length: 2)
            )
        )
    }

    func testInsertContentAtLocation() throws {
        let buffer = MutableStringBuffer("hi")

        try buffer.insert("🐞 bug", at: 1)

        XCTAssertEqual(buffer, "h🐞 bugi")
    }

    func testInsertOutOfBounds() {
        let buffer = MutableStringBuffer("hi")
        assertThrows(
            try buffer.insert("💣", at: 3),
            error: BufferAccessFailure.outOfRange(
                location: 3,
                available: .init(location: 0, length: 2)
            )
        )
    }

    func testInsertOverSelection() {
        let buffer = MutableStringBuffer("fizz buzz fizz buzz")

        let selectedRange = Buffer.Range(location: 5, length: 5)
        buffer.select(selectedRange)

        XCTAssertTrue(buffer.isSelectingText)
        assertBufferState(buffer, "fizz {buzz }fizz buzz")

        buffer.insert("")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz {^}fizz buzz")

        buffer.insert("foo ")
        assertBufferState(buffer, "fizz foo {^}fizz buzz")
    }

    func testSelectedRange() {
        let buffer = MutableStringBuffer("hi")

        // Precondition
        XCTAssertEqual(buffer.selectedRange, .init(location: 0, length: 0))
        XCTAssertFalse(buffer.isSelectingText)

        buffer.select(.init(location: 1, length: 1))

        // Postcondition
        XCTAssertEqual(buffer.selectedRange, .init(location: 1, length: 1))
        XCTAssertTrue(buffer.isSelectingText)
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
        buffer.insertionLocation = length(of: "Hello: wor")

        assertBufferState(buffer, "Hello: wor{^}ld!")

        buffer.delete(in: .init(location: 0, length: 4))
        buffer.delete(in: .init(location: 0, length: 4))

        assertBufferState(buffer, "or{^}ld!")
    }

    func testReplaceAroundInsertionPoint() {
        let buffer = MutableStringBuffer("Goodbye, cruel world!")
        buffer.insertionLocation = length(of: "Goodbye, cruel")

        assertBufferState(buffer, "Goodbye, cruel{^} world!")

        buffer.replace(range: .init(location: 9, length: 6), with: "")
        assertBufferState(buffer, "Goodbye, {^}world!")

        buffer.replace(range: .init(location: 0, length: 7), with: "Hello")
        assertBufferState(buffer, "Hello, {^}world!")
    }

    func testReplaceInSelectedRange() {
        let buffer = MutableStringBuffer("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor{em ip}sum")

        buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x{ip}sum")

        buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "y{^}um")
    }
}
