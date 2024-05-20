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

    func testSelect_BufferLocations() throws {
        try Select(0).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        try Select(10).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 0))

        try Select(-10).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_BufferRanges() throws {
        try Select(Buffer.Range(location: 0, length: 0)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 0, length: 0))

        try Select(Buffer.Range(location: 10, length: 2)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: 10, length: 2))

        try Select(Buffer.Range(location: -10, length: 1)).evaluate(in: textViewBuffer)
        XCTAssertEqual(textViewBuffer.selectedRange, .init(location: textViewBuffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }


    func testSelect_LineRanges() throws {
        func assertLineRanges(
            location: Buffer.Location,
            file: StaticString = #file, line: UInt = #line
        ) throws {
            let range = Buffer.Range(location: location, length: 0)

            try Select(LineRange(range)).evaluate(in: textViewBuffer)

            let expectedRange = textViewBuffer.lineRange(for: range)
            XCTAssertEqual(textViewBuffer.selectedRange, expectedRange, file: file, line: line)
        }

        for location in (textViewBuffer.range.lowerBound ..< textViewBuffer.range.upperBound) {
            try assertLineRanges(location: location)
        }

        try Select(LineRange(.init(location: 2, length: 10))).evaluate(in: textViewBuffer)
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
}
