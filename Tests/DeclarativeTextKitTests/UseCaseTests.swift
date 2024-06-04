//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class UseCaseTests: XCTestCase {
    func testWrapSelectionInFencedCodeBlock() throws {
        let buffer = Undoable(MutableStringBuffer("""
            # Heading

            Text here. It is
            not a lot of text.

            But it is nice.

            """))
        let selectedRange = Buffer.Range(location: 20, length: 11) // From line 3, "here", up to the next line.
        buffer.selectedRange = selectedRange

        assertBufferState(buffer, """
            # Heading

            Text here{. It is
            not} a lot of text.

            But it is nice.

            """)
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 0)
        }

        // MARK: 1) Perform modification with the DSL

        let changeInLength = try buffer.evaluate {
            Select(LineRange(selectedRange)) { lineRange in
                // Wrap selected text in code block
                Modifying(lineRange) { rangeToWrap in
                    Insert(rangeToWrap.location) { Line("```") }
                    Insert(rangeToWrap.endLocation) { Line("```") }
                }

                // Move insertion point to the position after the opening backticks
                Select(lineRange.location + length(of: "```"))
            }
        }

        XCTAssertEqual(changeInLength.delta, 2 * length(of: "```") + 2 /* newlines */)
        XCTAssertEqual(buffer.selectedRange, Buffer.Range(location: 14, length: 0))
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 1)
        }

        // MARK: 2) "Type" on behalf of the user

        try buffer.insert("raw")  // Simulate typing at the selection

        assertBufferState(buffer, """
            # Heading

            ```raw{^}
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)
        if #available(macOS 14.4, *) {
            XCTAssertEqual(buffer.undoManager?.undoCount, 2)
        }

        // MARK: 3) Undo typing

        buffer.undo()
        assertBufferState(buffer, """
            # Heading

            ```{^}
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)

        // MARK: 4) Undo transformation including the initial selection

        buffer.undo()

        assertBufferState(buffer, """
            # Heading

            Text here{. It is
            not} a lot of text.

            But it is nice.

            """)

        // MARK: 5) Redo transformation (checking that the undo of the undo works)

        buffer.redo()

        assertBufferState(buffer, """
            # Heading

            ```{^}
            Text here. It is
            not a lot of text.
            ```

            But it is nice.

            """)

        buffer.undo()

        assertBufferState(buffer, """
            # Heading

            Text here{. It is
            not} a lot of text.

            But it is nice.

            """)
    }
}
