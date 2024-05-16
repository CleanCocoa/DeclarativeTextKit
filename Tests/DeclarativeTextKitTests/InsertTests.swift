//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

extension Insert {
    func callAsFunction(intoBuffer buffer: Buffer) -> ChangeInLength {
        return evaluate(in: buffer)
    }
}

final class InsertTests: XCTestCase {
    var mutableString: NSMutableString = ""

    func testInsertString() throws {
        let insert = Insert(0) {
            "Hello,"
            " "
            "World"
            "!"
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString, "Hello, World!")
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_Lines_InEmptyDocument() {
        let insert = Insert(0) {
            Line("Hello, World!")
            Line("How are things lately?")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello, World!
            How are things lately?

            """)
        XCTAssertEqual(changeInLength, 37)
    }

    func testInsert_Lines_InsideParagraph() {
        mutableString = "Test Paragraph"
        let insert = Insert(4) {
            Line("Hello")
            Line("World!")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Test
            Hello
            World!
             Paragraph
            """)
        XCTAssertEqual(changeInLength, 14)
    }

    func testInsert_Line_And_String() {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World!
            """)
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_Line_And_String_And_Line() {
        let insert = Insert(0) {
            Line("Hello,")
            "World!"
            Line("What's up?")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength, 25)
    }

    func testInsert_Line_And_Strings() {
        let changeInLength = Insert(0) {
            Line("Hello,")
            "World! "
            "What's Up?"
        }(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World! What's Up?
            """)
        XCTAssertEqual(changeInLength, 24)
    }

    func testInsert_String_And_Line() {
        let insert = Insert(0) {
            "Hello,"
            Line("World")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World

            """)
        XCTAssertEqual(changeInLength, 13)
    }

    func testInsert_String_And_Lines() {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            Line("What's up?")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World!
            What's up?

            """)
        XCTAssertEqual(changeInLength, 25)
    }

    func testInsert_String_And_Line_And_String() {
        let insert = Insert(0) {
            "Hello,"
            Line("World!")
            "What's up?"
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            Hello,
            World!
            What's up?
            """)
        XCTAssertEqual(changeInLength, 24)
    }

    func testInsertMixed() {
        let insert = Insert(0) {
            "So,"
            Line("Hello, World!")
            Line("Now:")
            "I just wanted "
            "to ask:"
            Line("How are things lately?")
        }

        let changeInLength = insert(intoBuffer: mutableString)

        XCTAssertEqual(mutableString,
            """
            So,
            Hello, World!
            Now:
            I just wanted to ask:
            How are things lately?

            """)
        XCTAssertEqual(changeInLength, 68)
    }
}
