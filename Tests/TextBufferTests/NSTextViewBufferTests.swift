//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class NSTextViewBufferTests: XCTestCase {
    func testContent() {
        let string = "Test ⭐️ string 🚞 here"
        let buffer = textView(string)
        XCTAssertEqual(buffer.content, string)
        assertBufferState(buffer, "Test ⭐️ string 🚞 hereˇ",
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
            error: BufferAccessFailure.outOfRange(
                requested: .init(location: 2, length: 1),
                available: .init(location: 0, length: 2)
            )
        )
    }

    func testContentInRange_EmptyLength() throws {
        let buffer = textView("123")
        for location in buffer.range.location ..< buffer.range.endLocation + 1 /* Including the end location to get an empty substring should work */ {
            XCTAssertEqual(try buffer.content(in: .init(location: location, length: 0)), "")
        }
    }

    func testContentInRange_SingleCharacterLength() throws {
        let buffer = textView("123")
        let results = try (0 ..< 3)
            .map { try buffer.content(in: .init(location: $0, length: 1)) }
        XCTAssertEqual(results, ["1", "2", "3"])
    }

    func testContentInRange_CharacterPairs() throws {
        let buffer = textView("bug 🐞!")
        let utf16Offsets = try (0..<6).map { try buffer.content(in: .init(location: $0, length: 2)) }
        XCTAssertEqual(utf16Offsets, ["bu", "ug", "g ", " 🐞", "🐞", "🐞!"],
                       "The emoji is 2 scalar values wide and the underlying string should account for not splitting it")
    }

    func testContentInRange_OutOfBounds() throws {
        let buffer = textView("Lorem ipsum")
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

    func testInsertContentAtLocation() throws {
        let buffer = textView("hello bug!")
        buffer.selectedRange = .init(location: 6, length: 3)

        assertBufferState(buffer, "hello «bug»!")

        try buffer.insert(" 🐞", at: 5)

        assertBufferState(buffer, "hello 🐞 «bug»!")
    }

    func testInsertToAppend() throws {
        let buffer = textView("")

        assertBufferState(buffer, "ˇ")

        try buffer.insert("hello")
        assertBufferState(buffer, "helloˇ")

        try buffer.insert(" world")
        assertBufferState(buffer, "hello worldˇ")
    }

    func testInsertOverSelection() throws {
        let buffer = textView("fizz buzz fizz buzz")
        let selectedRange = Buffer.Range(location: 5, length: 10)
        buffer.select(selectedRange)

        assertBufferState(buffer, "fizz «buzz fizz »buzz")

        try buffer.insert("foo ")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz foo ˇbuzz")
    }

    func testInsertOutOfBounds() {
        let buffer = textView("hi")
        assertThrows(
            try buffer.insert("💣", at: 3),
            error: BufferAccessFailure.outOfRange(
                location: 3,
                available: .init(location: 0, length: 2)
            )
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
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 0, length: 0)), .init(location: 0, length: 3))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 3, length: 0)), .init(location: 3, length: 3))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 6, length: 0)), .init(location: 6, length: 2))

        // Wrapping lines
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 1, length: 3)), .init(location: 0, length: 6))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 4, length: 3)), .init(location: 3, length: 5))
        XCTAssertEqual(try buffer.lineRange(for: .init(location: 1, length: 7)), buffer.range)
    }

    func testLineRange_OutOfBounds() {
        let buffer = textView("aa\nbb\ncc")

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
        let buffer = textView("Lorem ipsum")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "Loremˇ ipsum")

        try buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "emˇ ipsum")

        try buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "ˇipsum")
    }

    func testDeleteInRange_EmptyLength() throws {
        let string = "123"
        for location in 0 ..< string.count + 1 /* Including the end location to get an empty substring should work */ {
            let buffer = textView(string)
            XCTAssertEqual(try buffer.content(in: .init(location: location, length: 0)), "")
            XCTAssertEqual(buffer.content, string, "Deleting empty range should not change string")
        }
    }

    func testDeleteOutsideBounds() {
        let buffer = textView("Lorem ipsum")
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
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx34ˇ56789")
    }

    func testReplace_AtInsertionPoint() throws {
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 5, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234xxxxˇ789")
    }

    func testReplace_AfterInsertionPoint() throws {
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234ˇ56789")

        try buffer.replace(range: .init(location: 6, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234ˇ5xxxx89")
    }

    func testReplace_BeforeSelectedRange() throws {
        let buffer = textView("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123«456»789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx3«456»789")
    }

    func testReplace_AfterSelectedRange() throws {
        let buffer = textView("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123«456»789")

        try buffer.replace(range: .init(location: 8, length: 1), with: "xxxx")
        assertBufferState(buffer, "0123«456»7xxxx9")
    }

    func testReplaceAroundInsertionPoint() throws {
        let buffer: Buffer = textView("Goodbye, cruel universe!")
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
        let buffer: Buffer = textView("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor«em ip»sum")

        try buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x«ip»sum")

        try buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "yˇum")
    }

    func testReplaceOutOfBounds() {
        let buffer: Buffer = textView("Lorem ipsum")
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

    func testModifying_DependsOnDelegate() throws {
        class Delegate: NSObject, NSTextViewDelegate {
            var shouldChangeText = false

            func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
                return shouldChangeText
            }
        }

        let buffer = textView("Text")
        let delegate = Delegate()
        buffer.textView.delegate = delegate

        // Forbidden
        delegate.shouldChangeText = false
        for location in buffer.range.location ..< buffer.range.endLocation {
            assertThrows(
                try buffer.modifying(affectedRange: .init(location: location, length: 0)) {
                    XCTFail("Modification at \(location) should not execute")
                },
                error: BufferAccessFailure.modificationForbidden(in: .init(location: location, length: 0))
            )
        }

        // Allowed
        delegate.shouldChangeText = true
        for location in buffer.range.location ..< buffer.range.endLocation {
            var didModify = false
            let result = try buffer.modifying(affectedRange: .init(location: location, length: 0)) {
                defer { didModify = true }
                return location * 2
            }
            XCTAssertTrue(didModify)
            XCTAssertEqual(result, location * 2)
        }
    }
}
