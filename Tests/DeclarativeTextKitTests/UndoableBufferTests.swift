//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

class Undoable<Base>: Buffer where Base: Buffer {
    private let base: Base

    var content: Base.Content { base.content }
    var range: Base.Range { base.range }
    var selectedRange: Base.Range {
        get { base.selectedRange }
        set { base.selectedRange = newValue }
    }

    let undoManager: UndoManager

    init(
        _ base: Base
    ) {
        self.base = base
        self.undoManager = UndoManager()
        self.undoManager.groupsByEvent = false
    }

    func lineRange(for range: Base.Range) -> Base.Range {
        return base.lineRange(for: range)
    }

    func content(in range: UTF16Range) throws -> Base.Content {
        return try base.content(in: range)
    }

    func unsafeCharacter(at location: Location) -> Base.Content {
        return base.unsafeCharacter(at: location)
    }

    func delete(in deletedRange: Base.Range) throws {
        let oldContent = try base.content(in: deletedRange)
        let oldSelection = base.selectedRange

        try base.delete(in: deletedRange)

        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.insert(oldContent, at: deletedRange.location)
            undoableBuffer.select(oldSelection)
        }
        undoManager.endUndoGrouping()
    }

    func replace(range replacementRange: Base.Range, with content: Base.Content) throws {
        let oldContent = try base.content(in: replacementRange)
        let oldSelection = base.selectedRange

        try base.replace(range: replacementRange, with: content)

        let newRange = Buffer.Range(location: replacementRange.location, length: length(of: content))
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.replace(range: newRange, with: oldContent)
            undoableBuffer.select(oldSelection)
        }
        undoManager.endUndoGrouping()
    }

    func insert(_ content: Base.Content, at location: Base.Location) throws {
        let oldSelection = base.selectedRange

        try base.insert(content, at: location)

        let newRange = Buffer.Range(location: location, length: length(of: content))
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.delete(in: newRange)
            undoableBuffer.select(oldSelection)
        }
        undoManager.endUndoGrouping()
    }

    func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        return try base.modifying(affectedRange: affectedRange, block)
    }

    func undo() {
        undoManager.undoNestedGroup()
    }

    func redo() {
        undoManager.redo()
    }
}

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

        try Modifying(buffer.range) { fullRange in
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
