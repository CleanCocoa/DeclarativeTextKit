//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class NSTextViewBufferTests: XCTestCase {
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
            error: BufferAccessFailure.outOfRange(
                location: 2,
                available: .init(location: 0, length: 2)
            )
        )
    }

    func testInsertContentAtLocation() throws {
        let buffer = textView("hello bug!")
        buffer.selectedRange = .init(location: 6, length: 3)

        assertBufferState(buffer, "hello {bug}!")

        try buffer.insert(" 🐞", at: 5)

        assertBufferState(buffer, "hello 🐞 {bug}!")
    }

    func testInsertToAppend() throws {
        let buffer = textView("")

        assertBufferState(buffer, "{^}")

        try buffer.insert("hello")
        assertBufferState(buffer, "hello{^}")

        try buffer.insert(" world")
        assertBufferState(buffer, "hello world{^}")
    }

    func testInsertOverSelection() throws {
        let buffer = textView("fizz buzz fizz buzz")
        let selectedRange = Buffer.Range(location: 5, length: 10)
        buffer.select(selectedRange)

        assertBufferState(buffer, "fizz {buzz fizz }buzz")

        try buffer.insert("foo ")
        XCTAssertFalse(buffer.isSelectingText, "Inserting goes out of selection mode")
        assertBufferState(buffer, "fizz foo {^}buzz")
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
        XCTAssertEqual(buffer.lineRange(for: .init(location: 0, length: 0)), .init(location: 0, length: 3))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 3, length: 0)), .init(location: 3, length: 3))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 6, length: 0)), .init(location: 6, length: 2))

        // Wrapping lines
        XCTAssertEqual(buffer.lineRange(for: .init(location: 1, length: 3)), .init(location: 0, length: 6))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 4, length: 3)), .init(location: 3, length: 5))
        XCTAssertEqual(buffer.lineRange(for: .init(location: 1, length: 7)), buffer.range)
    }

    func testDelete() throws {
        let buffer = textView("Lorem ipsum")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "Lorem{^} ipsum")

        try buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "em{^} ipsum")

        try buffer.delete(in: .init(location: 0, length: 3))
        assertBufferState(buffer, "{^}ipsum")
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
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx34{^}56789")
    }

    func testReplace_AtInsertionPoint() throws {
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 5, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234xxxx{^}789")
    }

    func testReplace_AfterInsertionPoint() throws {
        let buffer = textView("0123456789")
        buffer.insertionLocation = 5

        assertBufferState(buffer, "01234{^}56789")

        try buffer.replace(range: .init(location: 6, length: 2), with: "xxxx")
        assertBufferState(buffer, "01234{^}5xxxx89")
    }

    func testReplace_BeforeSelectedRange() throws {
        let buffer = textView("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123{456}789")

        try buffer.replace(range: .init(location: 1, length: 2), with: "xxxx")
        assertBufferState(buffer, "0xxxx3{456}789")
    }

    func testReplace_AfterSelectedRange() throws {
        let buffer = textView("0123456789")
        buffer.selectedRange = .init(location: 4, length: 3)

        assertBufferState(buffer, "0123{456}789")

        try buffer.replace(range: .init(location: 8, length: 1), with: "xxxx")
        assertBufferState(buffer, "0123{456}7xxxx9")
    }

    func testReplaceAroundInsertionPoint() throws {
        let buffer: Buffer = textView("Goodbye, cruel universe!")
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
        let buffer: Buffer = textView("Lorem ipsum")
        buffer.selectedRange = .init(location: 3, length: 5)

        assertBufferState(buffer, "Lor{em ip}sum")

        try buffer.replace(range: .init(location: 0, length: 6), with: "x")
        assertBufferState(buffer, "x{ip}sum")

        try buffer.replace(range: .init(location: 0, length: 4), with: "y")
        assertBufferState(buffer, "y{^}um")
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
                    XCTFail("Modification should not execute")
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
