//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

final class UndoableBufferTests: XCTestCase {
    func testInsertOverSelection_WithoutSelectionRestoration() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "helloˇ")

        try undoable.insert(" you")
        buffer.select(.init(location: length(of: "hello "), length: 3))
        assertBufferState(undoable, "hello «you»")

        try undoable.insert("world")
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello youˇ")

        undoable.redo()
        assertBufferState(undoable, "hello worldˇ")

        try undoable.insert("!")
        assertBufferState(undoable, "hello world!ˇ")

        undoable.undo()
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello youˇ")

        undoable.redo()
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello youˇ")

        undoable.undo()
        assertBufferState(undoable, "helloˇ")
    }

    func testInsertOverSelection_WithSelectionRestoration() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "helloˇ")

        try undoable.insert(" you")
        buffer.select(.init(location: length(of: "hello "), length: 3))
        assertBufferState(undoable, "hello «you»")

        try undoable.withSelectionRestoration(true) {
            try undoable.insert("world")
        }
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello «you»")

        undoable.redo()
        assertBufferState(undoable, "hello worldˇ")

        try undoable.withSelectionRestoration(true) {
            try undoable.insert("!")
        }
        assertBufferState(undoable, "hello world!ˇ")

        undoable.undo()
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello «you»")

        undoable.redo()
        assertBufferState(undoable, "hello worldˇ")

        undoable.undo()
        assertBufferState(undoable, "hello «you»")

        undoable.undo()
        assertBufferState(undoable, "helloˇ")
    }

    func testModifyingGroupsUndo() throws {
        let buffer = MutableStringBuffer("hello")
        buffer.insertionLocation = length(of: "hello")
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "helloˇ")

        try undoable.evaluate { fullRange in
            Modifying(fullRange) { fullRange in
                Insert(fullRange.endLocation) { " you" }
            }

            Select(WordRange(location: fullRange.endLocation)) { selectedRange in
                Assert(selectedRange, contains: "you")

                Modifying(selectedRange) { selectedRange in
                    Delete(selectedRange)
                }

                Modifying(selectedRange) { selectedRange in
                    Insert(selectedRange.endLocation) { "world" }
                    Insert(selectedRange.endLocation) { "!" }
                }
            }
        }

        assertBufferState(undoable, "hello world!ˇ")

        undoable.undo()
        assertBufferState(undoable, "helloˇ")

        undoable.redo()
        assertBufferState(undoable, "hello world!ˇ")
    }

    func testUndoingSelection() throws {
        let buffer = MutableStringBuffer("0123456789")
        buffer.insertionLocation = 0
        let undoable = Undoable(buffer)

        assertBufferState(undoable, "ˇ0123456789")

        undoable.insertionLocation += 1
        assertBufferState(undoable, "0ˇ123456789")
        undoable.undo()
        assertBufferState(undoable, "0ˇ123456789")

        undoable.undoGrouping { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "01ˇ23456789")
        undoable.undo()
        assertBufferState(undoable, "01ˇ23456789")

        undoable.undoGrouping(undoingSelectionChanges: false) { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "012ˇ3456789")
        undoable.undo()
        assertBufferState(undoable, "012ˇ3456789")

        undoable.undoGrouping(undoingSelectionChanges: true) { undoable.insertionLocation += 1 }
        assertBufferState(undoable, "0123ˇ456789")
        undoable.undo()
        assertBufferState(undoable, "012ˇ3456789")
    }
}
