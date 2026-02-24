import XCTest
import DeclarativeTextKit

@MainActor
final class UseCaseTests: XCTestCase {
    func testWrapSelectionInStrongEmphasis() throws {
        let buffer = Undoable(MutableStringBuffer("""
            Welcome, fellow traveller, to these barren lands!
            """))
        addTeardownBlock { [buffer] in _ = buffer }
        buffer.selectedRange = NSRange(
            location: length(of: "Welcome, fel"),
            length: length(of: "low travel")
        )

        assertBufferState(buffer, """
            Welcome, fel«low travel»ler, to these barren lands!
            """)

        let changeInLength = try buffer.evaluate {
            Select(WordRange(buffer.selectedRange)) { wordRange in
                Modifying(wordRange) { rangeToWrap in
                    Insert(rangeToWrap.location) { Word.Prepending("**") }
                    Insert(rangeToWrap.endLocation) { Word.Appending("**") }
                }

                Select(wordRange)
            }
        }
        XCTAssertEqual(changeInLength.delta, 4)

        assertBufferState(buffer, """
            Welcome, «**fellow traveller**», to these barren lands!
            """)

        buffer.undo()
        assertBufferState(buffer, """
            Welcome, fel«low travel»ler, to these barren lands!
            """)

        buffer.redo()
        assertBufferState(buffer, """
            Welcome, «**fellow traveller**», to these barren lands!
            """)
    }

    func testWrapSelectionInFencedCodeBlock() throws {
        let buffer = Undoable(MutableStringBuffer("""
            # Heading

            Text here. It is
            not a lot of text.

            But it is nice.

            """))
        addTeardownBlock { [buffer] in _ = buffer }
        let selectedRange = NSRange(location: 20, length: 11)
        buffer.selectedRange = selectedRange

        assertBufferState(buffer, """
            # Heading

            Text here«. It is
            not» a lot of text.

            But it is nice.

            """)
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 0)
        }

        let changeInLength = try buffer.evaluate {
            Select(LineRange(selectedRange)) { lineRange in
                Modifying(lineRange) { rangeToWrap in
                    Insert(rangeToWrap.location) { Line("```") }
                    Insert(rangeToWrap.endLocation) { Line("```") }
                }

                Select(lineRange.location + length(of: "```"))
            }
        }

        XCTAssertEqual(changeInLength.delta, 2 * length(of: "```") + 2)
        XCTAssertEqual(buffer.selectedRange, NSRange(location: 14, length: 0))
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 1)
        }

        try buffer.insert("raw")

        assertBufferState(buffer, """
            # Heading

            ```rawˇ
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 2)
        }

        buffer.undo()
        assertBufferState(buffer, """
            # Heading

            ```ˇ
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)

        buffer.undo()

        assertBufferState(buffer, """
            # Heading

            Text here«. It is
            not» a lot of text.

            But it is nice.

            """)

        buffer.redo()

        assertBufferState(buffer, """
            # Heading

            ```ˇ
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)

        buffer.undo()

        assertBufferState(buffer, """
            # Heading

            Text here«. It is
            not» a lot of text.

            But it is nice.

            """)
    }
}
