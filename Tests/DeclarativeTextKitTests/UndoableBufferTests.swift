//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class UndoableBufferTests: XCTestCase {
    func testInsertOverSelection_WithoutSelectionRestoration() throws {
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
        assertBufferState(undoable, "hello you{^}")

        undoable.redo()
        assertBufferState(undoable, "hello world{^}")

        try undoable.insert("!")
        assertBufferState(undoable, "hello world!{^}")

        undoable.undo()
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello you{^}")

        undoable.redo()
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello you{^}")

        undoable.undo()
        assertBufferState(undoable, "hello{^}")
    }

    func testInsertOverSelection_WithSelectionRestoration() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "hello{^}")

        try undoable.insert(" you")
        buffer.select(.init(location: length(of: "hello "), length: 3))
        assertBufferState(undoable, "hello {you}")

        try undoable.withSelectionRestoration(true) {
            try undoable.insert("world")
        }
        assertBufferState(undoable, "hello world{^}")

        undoable.undo()
        assertBufferState(undoable, "hello {you}")

        undoable.redo()
        assertBufferState(undoable, "hello world{^}")

        try undoable.withSelectionRestoration(true) {
            try undoable.insert("!")
        }
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

        _ = try undoable.evaluate {
            Modifying(SelectedRange(buffer.range)) { fullRange in
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
            }
        }

        assertBufferState(undoable, "hello world!{^}")

        undoable.undo()
        assertBufferState(undoable, "hello{^}")

        undoable.redo()
        assertBufferState(undoable, "hello world!{^}")
    }

    func testUndoingSelection() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 0
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "{^}0123456789")

        undoable.insertionLocation += 1
        assertBufferState(undoable, "0{^}123456789")
        undoable.undo()
        assertBufferState(undoable, "0{^}123456789")

        undoable.undoGrouping { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "01{^}23456789")
        undoable.undo()
        assertBufferState(undoable, "01{^}23456789")

        undoable.undoGrouping(undoingSelectionChanges: false) { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "012{^}3456789")
        undoable.undo()
        assertBufferState(undoable, "012{^}3456789")

        undoable.undoGrouping(undoingSelectionChanges: true) { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "0123{^}456789")
        undoable.undo()
        assertBufferState(undoable, "012{^}3456789")
    }
}
