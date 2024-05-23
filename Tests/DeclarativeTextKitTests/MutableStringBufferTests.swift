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

    func testInsertToAppend() throws {
        let buffer = MutableStringBuffer("")

        assertBufferState(buffer, "{^}")

        try buffer.insert("hello")
        assertBufferState(buffer, "hello{^}")

        try buffer.insert(" world")
        assertBufferState(buffer, "hello world{^}")
    }

    func testInsertContentAtLocation() throws {
        let buffer = MutableStringBuffer("hello bug!")
        buffer.selectedRange = .init(location: 6, length: 3)

        assertBufferState(buffer, "hello {bug}!")

        try buffer.insert(" 🐞", at: 5)

        assertBufferState(buffer, "hello 🐞 {bug}!")
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

    func testInsertOverSelection() throws {
        let buffer = MutableStringBuffer("fizz buzz fizz buzz")

        let selectedRange = Buffer.Range(location: 5, length: 10)
        buffer.select(selectedRange)

        XCTAssertTrue(buffer.isSelectingText)
        assertBufferState(buffer, "fizz {buzz fizz }buzz")

        try buffer.insert("foo ")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz foo {^}buzz")
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

    func testDelete() throws {
        let buffer = MutableStringBuffer("Hello: world!")
        buffer.insertionLocation = length(of: "Hello: wor")

        assertBufferState(buffer, "Hello: wor{^}ld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "o: wor{^}ld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "or{^}ld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "{^}!")
    }

    func testDeleteOutsideBounds() {
        let buffer = MutableStringBuffer("Lorem ipsum")
        let expectedAvailableRange = Buffer.Range(location: 0, length: 11)

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 11, length: -2),
            .init(location: 11, length: -1),
            .init(location: 1, length: 999),
            .init(location: 11, length: 0),
            .init(location: 11, length: 1),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.delete(in: invalidRange),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                )
            )
        }
    }

    func testReplace_BeforeInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx34{^}56789")
    }

    func testReplace_AtInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 5, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234xxxx{^}789")
    }

    func testReplace_AfterInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 6, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234{^}5xxxx89")
    }

    func testReplace_BeforeSelectedRange() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123{456}789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx3{456}789")
    }

    func testReplace_AfterSelectedRange() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123{456}789")

        try buffer.replace(range: .init(location: 8, length: 1), with: "xxxx")
        assertBufferState(buffer, "0123{456}7xxxx9")
    }

    func testReplaceAroundInsertionPoint() throws {
        let buffer = MutableStringBuffer("Goodbye, cruel universe!")
        buffer.insertionLocation = length(of: "Goodbye, cruel")

        assertBufferState(buffer, "Goodbye, cruel{^} universe!")

        try buffer.replace(range: .init(location: 9, length: 6), with: "")
        assertBufferState(buffer, "Goodbye, {^}universe!")

        try buffer.replace(range: .init(location: 0, length: 7), with: "Hello")
        assertBufferState(buffer, "Hello, {^}universe!")

        try buffer.replace(range: .init(location: 7, length: 8), with: "world")
        assertBufferState(buffer, "Hello, world{^}!")
    }

    func testReplaceInSelectedRange() throws {
        let buffer = MutableStringBuffer("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor{em ip}sum")

        try buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x{ip}sum")

        try buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "y{^}um")
    }

    func testReplaceOutOfBounds() {
        let buffer: Buffer = MutableStringBuffer("Lorem ipsum")
        let expectedAvailableRange = Buffer.Range(location: 0, length: 11)

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 1, length: 999),
            .init(location: 11, length: -2),
            .init(location: 11, length: -1),
            .init(location: 11, length: 1),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.replace(range: invalidRange, with: "x"),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                )
            )
        }
    }

    func testModifying_PassesThrough() throws {
        let buffer = MutableStringBuffer("Text")

        for location in buffer.range.location ..< buffer.range.endLocation {
            var didModify = false
            let result = try buffer.modifying(affectedRange: .init(location: location, length: 0)) {
                defer { didModify = true }
                return location * 3
            }
            XCTAssertTrue(didModify)
            XCTAssertEqual(result, location * 3)
        }
    }
}
