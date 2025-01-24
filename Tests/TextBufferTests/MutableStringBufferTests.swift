//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

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
                requested: .init(location: 2, length: 1),
                available: .init(location: 0, length: 2)
            )
        )
    }

    func testContentInRange_EmptyLength() throws {
        let buffer = MutableStringBuffer("123")
        for location in buffer.range.location ..< buffer.range.endLocation + 1 /* Including the end location to get an empty substring should work */ {
            XCTAssertEqual(try buffer.content(in: .init(location: location, length: 0)), "")
        }
    }

    func testContentInRange_SingleCharacterLength() throws {
        let buffer = MutableStringBuffer("123")
        let results = try (0 ..< 3)
            .map { try buffer.content(in: .init(location: $0, length: 1)) }
        XCTAssertEqual(results, ["1", "2", "3"])
    }

    func testContentInRange_CharacterPairs() throws {
        let buffer = MutableStringBuffer("bug 🐞!")
        let utf16Offsets = try (0..<6).map { try buffer.content(in: .init(location: $0, length: 2)) }
        XCTAssertEqual(utf16Offsets, ["bu", "ug", "g ", " 🐞", "🐞", "🐞!"],
                       "The emoji is 2 scalar values wide and the underlying string should account for not splitting it")
    }

    func testContentInRange_OutOfBounds() throws {
        let buffer = MutableStringBuffer("Lorem ipsum")
        let expectedAvailableRange = Buffer.Range(location: 0, length: 11)

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 11, length: -2),
            .init(location: 11, length: -1),
            .init(location: 1, length: 999),
            .init(location: 11, length: 1),
            .init(location: 12, length: 0),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.content(in: invalidRange),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                ),
                "Reading from \(invalidRange)"
            )
        }
    }

    func testInsertToAppend() throws {
        let buffer = MutableStringBuffer("")

        assertBufferState(buffer, "ˇ")

        try buffer.insert("hello")
        assertBufferState(buffer, "helloˇ")

        try buffer.insert(" world")
        assertBufferState(buffer, "hello worldˇ")
    }

    func testInsertContentAtLocation() throws {
        let buffer = MutableStringBuffer("hello bug!")
        buffer.selectedRange = .init(location: 6, length: 3)

        assertBufferState(buffer, "hello «bug»!")

        try buffer.insert(" 🐞", at: 5)

        assertBufferState(buffer, "hello 🐞 «bug»!")
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
        assertBufferState(buffer, "fizz «buzz fizz »buzz")

        try buffer.insert("foo ")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz foo ˇbuzz")
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

    func testLineRange() throws {
        let buffer = MutableStringBuffer("aa\nbb\ncc")

        // Individual lines
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 0, length: 0)), .init(location: 0, length: 3))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 3, length: 0)), .init(location: 3, length: 3))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 6, length: 0)), .init(location: 6, length: 2))

        // Wrapping lines
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 1, length: 3)), .init(location: 0, length: 6))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 4, length: 3)), .init(location: 3, length: 5))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 1, length: 7)), buffer.range)
    }

    func testLineRange_OutOfBounds() {
        let buffer = MutableStringBuffer("aa\nbb\ncc")

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 9, length: -2),
            .init(location: 9, length: -1),
            .init(location: 1, length: 999),
            .init(location: 9, length: 1),
            .init(location: 10, length: 0),
            .init(location: 100, length: 999),
        ]
        let expectedAvailableRange = Buffer.Range(location: 0, length: 8)
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.lineRange(for: invalidRange),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                ),
                "Accessing line range in \(invalidRange)"
            )
        }
    }

    func testDelete() throws {
        let buffer = MutableStringBuffer("Hello: world!")
        buffer.insertionLocation = length(of: "Hello: wor")

        assertBufferState(buffer, "Hello: worˇld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "o: worˇld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "orˇld!")

        try buffer.delete(in: .init(location: 0, length: 4))
        assertBufferState(buffer, "ˇ!")
    }

    func testDeleteInRange_EmptyLength() throws {
        let string = "123"
        for location in 0 ..< string.count + 1 /* Including the end location to get an empty substring should work */ {
            let buffer = MutableStringBuffer(string)
            XCTAssertEqual(try buffer.content(in: .init(location: location, length: 0)), "")
            XCTAssertEqual(buffer.content, string, "Deleting empty range should not change string")
        }
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
            .init(location: 11, length: 1),
            .init(location: 12, length: 0),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.delete(in: invalidRange),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                ),
                "Deleting in \(invalidRange)"
            )
        }
    }

    func testReplace_BeforeInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx34ˇ56789")
    }

    func testReplace_AtInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 5, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234xxxxˇ789")
    }

    func testReplace_AfterInsertionPoint() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 6, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234ˇ5xxxx89")
    }

    func testReplace_BeforeSelectedRange() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123«456»789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx3«456»789")
    }

    func testReplace_AfterSelectedRange() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123«456»789")

        try buffer.replace(range: .init(location: 8, length: 1), with: "xxxx")
        assertBufferState(buffer, "0123«456»7xxxx9")
    }

    func testReplaceAroundInsertionPoint() throws {
        let buffer = MutableStringBuffer("Goodbye, cruel universe!")
        buffer.insertionLocation = length(of: "Goodbye, cruel")

        assertBufferState(buffer, "Goodbye, cruelˇ universe!")

        try buffer.replace(range: .init(location: 9, length: 6), with: "")
        assertBufferState(buffer, "Goodbye, ˇuniverse!")

        try buffer.replace(range: .init(location: 0, length: 7), with: "Hello")
        assertBufferState(buffer, "Hello, ˇuniverse!")

        try buffer.replace(range: .init(location: 7, length: 8), with: "world")
        assertBufferState(buffer, "Hello, worldˇ!")
    }

    func testReplaceInSelectedRange() throws {
        let buffer = MutableStringBuffer("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor«em ip»sum")

        try buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x«ip»sum")

        try buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "yˇum")
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

    func testModifying_InBounds_PassesThrough() throws {
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

    func testModifying_OutOfBounds_Throws() throws {
        let buffer = MutableStringBuffer("Text")

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 3, length: 10),
            .init(location: 4, length: 2),
            .init(location: 5, length: 0),
            .init(location: 5, length: -2),
            .init(location: 5, length: -1),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.modifying(affectedRange: invalidRange) {
                    XCTFail("Modification in \(invalidRange) should not execute")
                },
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: .init(location: 0, length: 4)
                )
            )
        }
    }
}
