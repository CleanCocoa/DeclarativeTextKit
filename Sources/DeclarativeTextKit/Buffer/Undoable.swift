//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// Decorator of any ``Buffer`` to add undo/redo functionality through Foundation's `UndoManager`.
///
/// ## How undo grouping works
///
/// All direct mutations are wrapped in `beginUndoGrouping()`/`endUndoGrouping()` calls, so any deletion's and insertion's inverse action is added to the undo stack.
///
/// To group multiple buffer mutations in a single undo group, e.g. to delete parts of text in multiple places as one action, you can either
/// - use the ``Modifying-struct`` command from the DSL, which wraps its mutations in an undo group when applied to an ``Undoable`` buffer, or
/// - use the ``undoGrouping(actionName:_:)`` function directly.
///
/// ## Example
///
/// It's up to you and your requirements if you want hold on to the original, non-undoable buffer, or wrap it in ``Undoable-struct`` and then the resulting object instead.
///
/// This example demonstrates how a regular buffer is decorated with undo support and how the original is still perfectly usable:
///
/// ```swift
/// let buffer: Buffer = MutableStringBuffer("")
/// print(buffer) // => ""
///
/// let undoable = Undoable(buffer)
///
/// // Combine changes into one operation:
/// undoable.undoGrouping {
///     undoable.insert("World", at: 0)
///     undoable.insert("Hello, ", at: 0)
/// }
/// print(buffer) // => "Hello, World"
///
/// undoable.undo()
/// print(buffer) // => ""
///
/// undoable.redo()
/// print(buffer) // => "Hello, World"
/// ```
public final class Undoable<Base>: Buffer where Base: Buffer {
    private let base: Base

    public var content: Base.Content { base.content }
    public var range: Base.Range { base.range }
    public var selectedRange: Base.Range {
        get { base.selectedRange }
        set { base.selectedRange = newValue }
    }

    public let undoManager: UndoManager

    /// Wraps `base` to support automatic undo/redo of buffer mutations.
    ///
    /// > Warning: Nesting `Undoable<Undoable<Undoable<...>>>` is technically possible, but undefined.
    ///
    /// - Parameters:
    ///   - base: Buffer to add undo support for.
    ///   - undoManager: Undo manager to use for undo grouping. By default uses a new `UndoManager` instance per buffer that disables `groupsByEvent` to manually control event grouping instead of automatically grouping operations per `RunLoop` iteration.
    public init(
        _ base: Base,
        undoManager: UndoManager = {
            let undoManager = UndoManager()
            undoManager.groupsByEvent = false
            return undoManager
        }()
    ) {
        self.base = base
        self.undoManager = undoManager
    }

    public func lineRange(for range: Base.Range) -> Base.Range {
        return base.lineRange(for: range)
    }

    public func content(in range: UTF16Range) throws -> Base.Content {
        return try base.content(in: range)
    }

    public func unsafeCharacter(at location: Location) -> Base.Content {
        return base.unsafeCharacter(at: location)
    }

    public func delete(in deletedRange: Base.Range) throws {
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

    public func replace(range replacementRange: Base.Range, with content: Base.Content) throws {
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

    public func insert(_ content: Base.Content, at location: Base.Location) throws {
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

    /// Wrapping changes inside `block` in a modification request to bundle updates.
    ///
    /// Treats `block` as a single undoable action group. See ``undoGrouping(actionName:_:)``
    ///
    /// - Throws: ``BufferAccessFailure`` if changes to `affectedRange` are not permitted.
    public func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        return try undoGrouping {
            return try base.modifying(affectedRange: affectedRange, block)
        }
    }
}

// MARK: - Undo/Redo
extension Undoable {
    /// Treat `block` as a single undoable action group.
    ///
    /// Wraps the execution of `block` in `UndoManager`  `beginUndoGrouping()`/`endUndoGrouping()` calls to achieve the grouping.
    ///
    /// - Parameters:
    ///   - actionName: User-facing action name to set. Can be shown in the Undo/Redo main menu items. `nil` doesn't set any and preserves action names set elsewhere (default).
    ///   - block: Actions to run inside an undo group.
    @inlinable
    public func undoGrouping<T>(
        actionName: String? = nil,
        _ block: () throws -> T
    ) rethrows -> T {
        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        if let actionName {
            undoManager.setActionName(actionName)
        }
        return try block()
    }

    public func undo() {
        undoManager.undoNestedGroup()
    }

    public func redo() {
        undoManager.redo()
    }
}
