import XCTest
import DeclarativeTextKit

final class InsertTests: XCTestCase {
    var textView: NSTextView!

    override func setUp() async throws {
        textView = await NSTextView(usingTextLayoutManager: false)
    }

    override func tearDown() async throws {
        textView = nil
    }

    func testInsertString() throws {
        Insert(0) {
            "Hello,"
            " "
            "World"
            "!"
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string, "Hello, World!")
    }

    func testInsert_Lines_InEmptyDocument() {
        Insert(0) {
            Line("Hello, World!")
            Line("How are things lately?")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string, 
            """
            Hello, World!
            How are things lately?

            """)
    }

    func testInsert_Lines_InsideParagraph() {
        textView.string = "Test Paragraph"

        Insert(4) {
            Line("Hello")
            Line("World!")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Test
            Hello
            World!
             Paragraph
            """)
    }

    func testInsert_Line_And_String() {
        Insert(0) {
            Line("Hello,")
            "World!"
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World!
            """)
    }

    func testInsert_Line_And_String_And_Line() {
        Insert(0) {
            Line("Hello,")
            "World!"
            Line("What's up?")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World!
            What's up?

            """)
    }

    func testInsert_Line_And_Strings() {
        Insert(0) {
            Line("Hello,")
            "World! "
            "What's Up?"
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World! What's Up?
            """)
    }

    func testInsert_String_And_Line() {
        Insert(0) {
            "Hello,"
            Line("World")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World

            """)
    }

    func testInsert_String_And_Lines() {
        Insert(0) {
            "Hello,"
            Line("World!")
            Line("What's up?")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World!
            What's up?

            """)
    }

    func testInsert_String_And_Line_And_String() {
        Insert(0) {
            "Hello,"
            Line("World!")
            "What's up?"
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            Hello,
            World!
            What's up?
            """)
    }

    func testInsertMixed() {
        Insert(0) {
            "So,"
            Line("Hello, World!")
            Line("Now:")
            "I just wanted "
            "to ask:"
            Line("How are things lately?")
        }(intoBuffer: textView)

        XCTAssertEqual(textView.string,
            """
            So,
            Hello, World!
            Now:
            I just wanted to ask:
            How are things lately?

            """)
    }
}
