//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

extension Insert {
    func callAsFunction(intoBuffer buffer: Buffer) throws -> ChangeInLength {
        return try evaluate(in: buffer)
    }
}

final class InsertTests: XCTestCase {
    var buffer = MutableStringBuffer("")

    func testInsertString() throws {
        let insert = Insert(0) {
            "Hello,"
            " "
            "World"
            "!"
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content, "Hello, World!")
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_Lines_InEmptyDocument() throws {
        let insert = Insert(0) {
            Line("Hello, World!")
            Line("How are things lately?")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello, World!
            How are things lately?

            """)
        XCTAssertEqual(changeInLength, 37)
    }

    func testInsert_Lines_InsideParagraph() throws {
        buffer = MutableStringBuffer("Test Paragraph")
        let insert = Insert(4) {
            Line("Hello")
            Line("World!")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Test
            Hello
            World!
             Paragraph
            """)
        XCTAssertEqual(changeInLength, 14)
    }

    func testInsert_Line_And_String() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            """)
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_Line_And_String_And_Line() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
            Line("What's up?")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength, 25)
    }

    func testInsert_Line_And_Strings() throws {
        let insert = Insert(0) {
            Line("Hello,")
            "World! "
            "What's Up?"
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World! What's Up?
            """)
        XCTAssertEqual(changeInLength, 24)
    }

    func testInsert_String_And_Line() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World

            """)
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_String_And_Lines() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            Line("What's up?")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength, 25)
    }

    func testInsert_String_And_Line_And_String() throws {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            "What's up?"
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            Hello,
            World!
            What's up?
            """)
        XCTAssertEqual(changeInLength, 24)
    }

    func testInsertMixed() throws {
        let insert = Insert(0) {
            "So,"
            Line("Hello, World!")
            Line("Now:")
            "I just wanted "
            "to ask:"
            Line("How are things lately?")
        }

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            So,
            Hello, World!
            Now:
            I just wanted to ask:
            How are things lately?

            """)
        XCTAssertEqual(changeInLength, 68)
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

        let changeInLength = try insert(intoBuffer: buffer)

        XCTAssertEqual(buffer.content,
            """
            This time,
            there is already apparently
            A. Lot.
            Of
            existing text.

            """)
        XCTAssertEqual(changeInLength, 31)
    }
}
