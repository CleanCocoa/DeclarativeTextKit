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
        let runner = Insert.Runner(textView: textView)

        runner(Insert(0) {
            "Hello,"
            " "
            "World"
            "!"
        })

        XCTAssertEqual(textView.string, "Hello, World!")
    }

    func testInsert_Lines_InEmptyDocument() {
        let runner = Insert.Runner(textView: textView)

        runner(Insert(0) {
            Line("Hello, World!")
            Line("How are things lately?")
        })

        XCTAssertEqual(textView.string, 
            """
            Hello, World!
            How are things lately?

            """)
    }

    func testInsert_Lines_InsideParagraph() {
        textView.string = "Test Paragraph"
        let runner = Insert.Runner(textView: textView)

        runner(Insert(4) {
            Line("Hello")
            Line("World!")
        })

        XCTAssertEqual(textView.string,
            """
            Test
            Hello
            World!
             Paragraph
            """)
    }

    func testInsertMixed() {
        let runner = Insert.Runner(textView: textView)

        runner(Insert(0) {                  // Reduce tuples
            "So,"                           // String
            Line("Hello, World!")           // (String, Line)
            "I just wanted "                // ((String, Line), String)
            "to ask:"                       // (((String, Line), String), String)
            Line("How are things lately?")  // ((((String, Line), String), String), Line)
        })

        XCTAssertEqual(textView.string,
            """
            So,
            Hello, World!
            I just wanted to ask:
            How are things lately?

            """)
    }
}
