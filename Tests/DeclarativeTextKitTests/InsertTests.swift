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

    func testInsertLines() throws {
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
}
