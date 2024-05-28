//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class UndoableBufferTests: XCTestCase {
    func testInsertOverSelection() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "hello{^}")

        try undoable.insert(" you")
        buffer.select(.init(location: length(of: "hello "), length: 3))
        assertBufferState(undoable, "hello {you}")

        try undoable.insert("world")
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello {you}")

        undoable.redo()
        assertBufferState(undoable, "hello world{^}")

        try undoable.insert("!")
        assertBufferState(undoable, "hello world!{^}")

        undoable.undo()
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello {you}")

        undoable.redo()
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello {you}")

        undoable.undo()
        assertBufferState(undoable, "hello{^}")
    }

    func testModifyingGroupsUndo() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "hello{^}")

        _ = try Modifying(SelectedRange(buffer.range)) { fullRange in
            Modifying(fullRange) { fullRange in
                Insert(fullRange.endLocation) { " you" }
            }

            Select(location: fullRange.endLocation + 1, length: 3) { selectedRange in
                Modifying(selectedRange) { selectedRange in
                    Delete(selectedRange)
                }

                Modifying(selectedRange) { selectedRange in
                    Insert(selectedRange.endLocation) { "world" }
                    Insert(selectedRange.endLocation) { "!" }
                }
            }
        }.evaluate(in: undoable)

        assertBufferState(undoable, "hello world!{^}")

        undoable.undo()
        assertBufferState(undoable, "hello{^}")

        undoable.redo()
        assertBufferState(undoable, "hello world!{^}")
    }
}
