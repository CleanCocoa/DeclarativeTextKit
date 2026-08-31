import XCTest
import DeclarativeTextKit

fileprivate func * (
    amount: Int,
    string: String
) -> [String] {
    return (0 ..< amount).map { _ in string }
}

fileprivate func dump(_ diff: CollectionDifference<String>) -> String {
    var expecteds: [String] = [ "Expected:" ]
    var unexpecteds: [String] = [ "Unexpected:" ]
    for change in diff {
        switch change {
        case let .insert(offset: index, element: element, associatedWith: nil):
            expecteds.append("- \(element) at \(index)")
        case let .insert(offset: index, element: element, associatedWith: association):
            expecteds.append("- \(element) at \(index) (\(association!))")
        case let .remove(offset: index, element: element, associatedWith: nil):
            unexpecteds.append("- \(element) at \(index)")
        case let .remove(offset: index, element: element, associatedWith: association):
            unexpecteds.append("- \(element) at \(index) (\(association!))")
        }
    }
    return expecteds.joined(separator: "\n") + "\n" + unexpecteds.joined(separator: "\n")
}

@MainActor
final class SelectTests: XCTestCase {
    var buffer: (any ModifiableBuffer)!

    override func setUp() async throws {
        self.buffer = textView("""
            Hello!

            This is a test.

            """)
    }

    override func tearDown() async throws {
        self.buffer = nil
    }

    func testEvaluateBlockCompatibility() throws {
        let changeInLength = try MutableStringBuffer("").evaluate {
            Select(0)
        }
        XCTAssertEqual(changeInLength.delta, 0)
    }

    func testSelect_DoesNotChangeInLength() throws {
        buffer = MutableStringBuffer("012")

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

        XCTAssertEqual(try Select(LineRange(location: 0, length: 1)).evaluate(in: buffer).delta, 0)
    }

    func testSelect_BufferLocations() throws {
        _ = try Select(0).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: 0, length: 0))

        _ = try Select(10).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: 10, length: 0))

        _ = try Select(-10).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: buffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_BufferRanges() throws {
        _ = try Select(NSRange(location: 0, length: 0)).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: 0, length: 0))

        _ = try Select(NSRange(location: 10, length: 2)).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: 10, length: 2))

        _ = try Select(NSRange(location: -10, length: 1)).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, .init(location: buffer.range.upperBound, length: 0),
                       "Negative ranges wrap around (in text views)")
    }

    func testSelect_WordRanges() throws {
        buffer = MutableStringBuffer("Lorem ipsum\ndolor (sit amet) mkay?")

        let collectedWords: [String] = try (buffer.range.lowerBound ... buffer.range.upperBound)
            .reduce([]) { partialResult, location in
                let range = NSRange(location: location, length: 0)
                XCTAssertNoThrow(try Select(WordRange(range)).evaluate(in: buffer))
                return partialResult + [try buffer.content(in: buffer.selectedRange)]
            }

        let expectedSelections: [String] = ([
            6 * "Lorem",
            6 * "ipsum",
            6 * "dolor",
            1 * "(sit",
            4 * "sit",
            5 * "amet",
            1 * "amet)",
            5 * "mkay",
            1 * "mkay?",
        ] as [[String]]).flatMap { $0 }

        let diff = expectedSelections.difference(from: collectedWords).inferringMoves()
        XCTAssertEqual(collectedWords, expectedSelections, "\(dump(diff))")
    }

    func testSelect_RepeatedWordRange() throws {
        let buf = MutableStringBuffer("Lorem ipsum dolor.")
        buf.insertionLocation = length(of: "Lorem ")

        assertBufferState(buf, "Lorem ˇipsum dolor.")

        try buf.select(WordRange(buf.selectedRange))
        assertBufferState(buf, "Lorem «ipsum» dolor.")

        try buf.select(WordRange(buf.selectedRange))
        assertBufferState(buf, "Lorem «ipsum» dolor.",
                          "Selecting the same word again does not expand selection.")
    }


    func testSelect_WordRangeFromModification() throws {
        let buf = MutableStringBuffer("makewordshere")

        try buf.evaluate(
            location: length(of: "make"),
            length: length(of: "words")
        ) { selectedRange in
            Modifying(selectedRange) { wrappedRange in
                Insert(wrappedRange.location) { " " }
                Insert(wrappedRange.endLocation) { " " }
            }
            Select(WordRange(selectedRange))
        }

        assertBufferState(buf, "make «words» here")
    }

    func testSelect_LineRanges() throws {
        func assertLineRanges(
            location: Int,
            file: StaticString = #file, line: UInt = #line
        ) throws {
            let range = NSRange(location: location, length: 0)

            _ = try Select(LineRange(range)).evaluate(in: buffer)

            let expectedRange = try buffer.lineRange(for: range)
            XCTAssertEqual(buffer.selectedRange, expectedRange, file: file, line: line)
        }

        for location in (buffer.range.lowerBound ..< buffer.range.upperBound) {
            try assertLineRanges(location: location)
        }

        _ = try Select(LineRange(location: 2, length: 10)).evaluate(in: buffer)
        XCTAssertEqual(buffer.selectedRange, buffer.range)
    }

    func testSelect_RepeatedLineRange() throws {
        let buffer = MutableStringBuffer("""
            Lorem ipsum
            dolor sit amet,
            consectetur adipisicing.
            """)

        assertBufferState(buffer, """
            ˇLorem ipsum
            dolor sit amet,
            consectetur adipisicing.
            """)

        try buffer.select(LineRange(buffer.selectedRange))
        assertBufferState(buffer, """
            «Lorem ipsum
            »dolor sit amet,
            consectetur adipisicing.
            """)

        try buffer.select(LineRange(buffer.selectedRange))
        assertBufferState(buffer, """
            «Lorem ipsum
            »dolor sit amet,
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
        let selectedRange = NSRange(location: 20, length: 11)
        buffer.select(selectedRange)
        assertBufferState(buffer, """
            # Heading

            Text here«. It is
            not» a lot of text.

            But it is nice.

            """)

        _ = try Select(LineRange(selectedRange)).evaluate(in: buffer)
        assertBufferState(buffer, """
            # Heading

            «Text here. It is
            not a lot of text.
            »
            But it is nice.

            """)
    }
}
