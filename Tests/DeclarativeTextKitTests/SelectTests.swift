//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class SelectTests: XCTestCase {
    var textViewBuffer: Buffer!

    override func setUp() async throws {
        await MainActor.run {
            self.textViewBuffer = textView("""
Hello!

This is a test.

""")
        }
    }

    override func tearDown() async throws {
        self.textViewBuffer = nil
    }

    func testSelect_DoesNotChangeInLength() throws {
        let buffer = MutableStringBuffer("012")

        XCTAssertEqual(try Select(0).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(1).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(2).evaluate(in: buffer).delta, 0)

        XCTAssertEqual(try Select(location: 0, length: 0).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 1, length: 0).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 2, length: 0).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 3, length: 0).evaluate(in: buffer).delta, 0)

        XCTAssertEqual(try Select(location: 0, length: 1).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 1, length: 1).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 2, length: 1).evaluate(in: buffer).delta, 0)

        XCTAssertEqual(try Select(location: 0, length: 2).evaluate(in: buffer).delta, 0)
        XCTAssertEqual(try Select(location: 1, length: 2).evaluate(in: buffer).delta, 0)

        XCTAssertEqual(try Select(location: 0, length: 3).evaluate(in: buffer).delta, 0)

        XCTAssertEqual(try Select(LineRange(.init(location: 0, length: 1))).evaluate(in: buffer).delta, 0)
    }

    func testSelect_BufferLocations() throws {
        _ = try Select(0).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        _ = try Select(10).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 0))

        _ = try Select(-10).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_BufferRanges() throws {
        _ = try Select(Buffer.Range(location: 0, length: 0)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        _ = try Select(Buffer.Range(location: 10, length: 2)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 2))

        _ = try Select(Buffer.Range(location: -10, length: 1)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_LineRanges() throws {
        func assertLineRanges(
            location: Buffer.Location,
            file: StaticString = #file, line: UInt = #line
        ) throws {
            let range = Buffer.Range(location: location, length: 0)

            _ = try Select(LineRange(range)).evaluate(in: textViewBuffer)

            let expectedRange = textViewBuffer.lineRange(for: range)
            XCTAssertEqual(textViewBuffer.selectedRange, expectedRange, file: file, line: line)
        }

        for location in (textViewBuffer.range.lowerBound ..< textViewBuffer.range.upperBound) {
            try assertLineRanges(location: location)
        }

        _ = try Select(LineRange(.init(location: 2, length: 10))).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, textViewBuffer.range)
    }

    func testSelect_RepeatedLineRange() {
        let buffer = MutableStringBuffer("""
Lorem ipsum
dolor sit amet,
consectetur adipisicing.
""")

        assertBufferState(buffer, """
{^}Lorem ipsum
dolor sit amet,
consectetur adipisicing.
""")

        buffer.select(LineRange(buffer.selectedRange))
        assertBufferState(buffer, """
{Lorem ipsum
}dolor sit amet,
consectetur adipisicing.
""")

        buffer.select(LineRange(buffer.selectedRange))
        assertBufferState(buffer, """
{Lorem ipsum
}dolor sit amet,
consectetur adipisicing.
""", "Selecting the same line again 'as a line' does not expand selection.")
    }

    func testSelect_LineRangeInRealDocument() throws {
        let buffer = MutableStringBuffer("""
# Heading

Text here. It is
not a lot of text.

But it is nice.

""")
        let selectedRange = Buffer.Range(location: 20, length: 11)
        buffer.select(selectedRange)
        assertBufferState(buffer, """
# Heading

Text here{. It is
not} a lot of text.

But it is nice.

""")

        _ = try Select(LineRange(selectedRange)).evaluate(in: buffer)
        assertBufferState(buffer, """
# Heading

{Text here. It is
not a lot of text.
}
But it is nice.

""")
    }
}
