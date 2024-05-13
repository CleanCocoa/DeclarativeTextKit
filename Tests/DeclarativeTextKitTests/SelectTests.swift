//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class SelectTests: XCTestCase {
    @MainActor func textView(_ string: String) -> NSTextView {
        let textView = NSTextView(usingTextLayoutManager: false)
        textView.string = string
        return textView
    }

    var textViewBuffer: Buffer!

    override func setUp() async throws {
        self.textViewBuffer = await textView("""
Hello!

This is a test.

""")
    }

    override func tearDown() async throws {
        self.textViewBuffer = nil
    }

    func testSelect_BufferLocations() {
        Select(0).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        Select(10).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 0))

        Select(-10).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_BufferRanges() {
        Select(Buffer.Range(location: 0, length: 0)).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        Select(Buffer.Range(location: 10, length: 2)).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 2))

        Select(Buffer.Range(location: -10, length: 1)).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }


    func testSelect_LineRanges() {
        func assertLineRanges(
            location: Buffer.Location,
            file: StaticString = #file, line: UInt = #line
        ) {
            let range = Buffer.Range(location: location, length: 0)
            let selection = Select(LineRange(range)).evaluate(in: textViewBuffer)

            selection()

            let expectedRange = textViewBuffer.lineRange(for: range)
            XCTAssertEqual(textViewBuffer.selectedRange, expectedRange, file: file, line: line)
        }

        for location in (textViewBuffer.range.lowerBound ..< textViewBuffer.range.upperBound) {
            assertLineRanges(location: location)
        }

        Select(LineRange(.init(location: 2, length: 10))).evaluate(in: textViewBuffer)()
        XCTAssertEqual(textViewBuffer.selectedRange, textViewBuffer.range)
    }
}
