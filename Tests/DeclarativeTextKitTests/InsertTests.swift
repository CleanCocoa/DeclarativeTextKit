//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class InsertTests: XCTestCase {
    var buffer = MutableStringBuffer("")

    // MARK: - String

    func testInsert_String() throws {
        let insert = Insert(0) {
            "Hello,"
            " "
            "World"
            "!"
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Hello, World!")
        XCTAssertEqual(changeInLength.delta, 13)
    }

    // MARK: - Word

    func testInsert_Word_InEmptyDocument() throws {
        let insert = Insert(0) {
            Word("Hi")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Hi")
        XCTAssertEqual(changeInLength.delta, 2)
    }

    func testInsert_Word_InSequenceOfSpaces() throws {
        buffer = MutableStringBuffer(String(repeating: " ", count: 8))
        let insert = Insert(4) {
            Word("Hi")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "    Hi    ")
        XCTAssertEqual(changeInLength.delta, 2)
    }

    func testInsert_Word_BetweenNewlines() throws {
        buffer = MutableStringBuffer(String(repeating: "\n", count: 4))
        let insert = Insert(2) {
            Word("Hi")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "\n\nHi\n\n")
        XCTAssertEqual(changeInLength.delta, 2)
    }

    func testInsert_MultipleWords_InEmptyDocument() throws {
        let insert = Insert(0) {
            Word("Hi")
            Word("there")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Hi there")
        XCTAssertEqual(changeInLength.delta, 8)
    }

    func testInsert_MultipleWords_InsideLongWord() throws {
        buffer = MutableStringBuffer("Delicious")

        let insert = Insert(length(of: "Deli")) {
            Word("ad")
            Word("break")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content, "Deli ad break cious")
        XCTAssertEqual(changeInLength.delta, 10)
    }

    func testInsert_MultipleWords_BetweenWords_ReusesExistingWhitespace() throws {
        let string = "we hate"
        let insertBeforeSpace = Insert(length(of: "we")) {
            Word("ad")
            Word("break")
        }
        let insertAfterSpace = Insert(length(of: "we ")) {
            Word("ad")
            Word("break")
        }

        let expectedString = "we ad break hate"

        buffer = MutableStringBuffer(string)
        let changeInLengthBeforeSpace = try insertBeforeSpace.evaluate(in: buffer)
        XCTAssertEqual(buffer.content, expectedString)
        XCTAssertEqual(changeInLengthBeforeSpace.delta, 9)

        buffer = MutableStringBuffer(string)
        let changeInLengthAfterSpace = try insertAfterSpace.evaluate(in: buffer)
        XCTAssertEqual(buffer.content, expectedString)
        XCTAssertEqual(changeInLengthAfterSpace.delta, 9)
    }

    // MARK: - Line

    func testInsert_Lines_InEmptyDocument() throws {
        let insert = Insert(0) {
            Line("Hello, World!")
            Line("How are things lately?")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello, World!
            How are things lately?

            """)
        XCTAssertEqual(changeInLength.delta, 37)
    }

    func testInsert_Lines_InsideParagraph() throws {
        buffer = MutableStringBuffer("Test Paragraph")
        let insert = Insert(4) {
            Line("Hello")
            Line("World!")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Test
            Hello
            World!
             Paragraph
            """)
        XCTAssertEqual(changeInLength.delta, 14)
    }

    // MARK: - Line and String

    func testInsert_Line_And_String() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            """)
        XCTAssertEqual(changeInLength.delta, 13)
    }

    func testInsert_Line_And_String_And_Line() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
            Line("What's up?")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength.delta, 25)
    }

    func testInsert_Line_And_Strings() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World! "
            "What's Up?"
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World! What's Up?
            """)
        XCTAssertEqual(changeInLength.delta, 24)
    }

    func testInsert_String_And_Line() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World

            """)
        XCTAssertEqual(changeInLength.delta, 13)
    }

    func testInsert_String_And_Lines() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            Line("What's up?")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength.delta, 25)
    }

    func testInsert_String_And_Line_And_String() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            "What's up?"
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?
            """)
        XCTAssertEqual(changeInLength.delta, 24)
    }

    // MARK: - Mixing naturally

    func testInsertMixed() throws {
        let insert = Insert(0) {
            "So,"
            Line("Hello, World!")
            Line("Now:")
            "I just wanted "
            "to ask:"
            Line("How are things lately?")
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            So,
            Hello, World!
            Now:
            I just wanted to ask:
            How are things lately?

            """)
        XCTAssertEqual(changeInLength.delta, 68)
    }

    func testInsertMixedIntoPreexistingText() throws {
        buffer = MutableStringBuffer("""
            This time,
            there is already text.

            """)
        let insert = Insert(length(of: "This time,\nthere is already ")) {
            "apparently"
            Line("A. Lot.")
            Line("Of")
            "existing "
        }

        let changeInLength = try insert.evaluate(in: buffer)

        XCTAssertEqual(buffer.content,
            """
            This time,
            there is already apparently
            A. Lot.
            Of
            existing text.

            """)
        XCTAssertEqual(changeInLength.delta, 31)
    }
}
