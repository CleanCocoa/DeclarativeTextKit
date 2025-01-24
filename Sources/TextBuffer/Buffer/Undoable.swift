//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// Decorator of any ``Buffer`` to add undo/redo functionality through Foundation's `UndoManager`.
///
/// ## How Undo Grouping Works
///
/// All direct mutations are wrapped in `beginUndoGrouping()`/`endUndoGrouping()` calls, so any deletion's and insertion's inverse action is added to the undo stack.
///
/// To group multiple buffer mutations in a single undo group, e.g. to delete parts of text in multiple places as one action, you can either
/// - use the ``Modifying-struct`` command from the DSL, which wraps its mutations in an undo group when applied to an ``Undoable`` buffer, or
/// - use the ``undoGrouping(actionName:undoingSelectionChanges:_:)`` function directly.
///
/// ## Caveats and Pitfalls
///
/// You need to make sure that the ``Undoable`` instance stays in memory (there's at least 1 strong reference) for undoing to work, especially if you register with the "global" undo manager of the current window.
///
/// Conversely, you can't treat ``Undoable`` instances as lightweight wrappers that you throw away after use. That would effectively remove all undoable actions.
///
/// **Reason:** ``Undoable`` removes all undo groups from its ``undoManager`` upon deinitialization. If you've ever worked with the block-based `UndoManager.registerUndo(withTarget:handler:)`, you know that the `target` parameter is not retained. It's an unowned reference. We can't keep the undoable action on the undo stack when the target, your ``Undoable`` buffer, is gone. It cleans up after itself to avoid crashes.
///
/// ## Example
///
/// It's up to you and your requirements if you want hold on to the original, non-undoable buffer, or wrap it in ``Undoable`` and then the resulting object instead.
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
        set {
            guard let undoManager
            else { preconditionFailure("Undoable buffer used without UndoManager") }

            let oldSelection = base.selectedRange

            base.selectedRange = newValue

            guard isRestoringSelection else { return }

            undoManager.beginUndoGrouping()
            undoManager.registerUndo(withTarget: self) { undoableBuffer in
                undoableBuffer.withSelectionRestoration(true) {
                    undoableBuffer.selectedRange = oldSelection
                }
            }
            undoManager.endUndoGrouping()
        }
    }

    /// Whether inverse of `select(_:)` commands should also be added to the undo stack.
    @usableFromInline
    var isRestoringSelection: Bool = false

    /// Lazy `UndoManager` access. Required to support `NSTextView`'s default behavior of not shipping with its own `UndoManager`, but delegating to the window or document.
    @usableFromInline
    let getUndoManager: () -> UndoManager?

    /// Undo manager used by the buffer.
    ///
    /// By default, this is lazily evaluated to support using the `NSTextView`/`UITextView` behavior of bubbling up undo manager access up the responder chain until their window is reached. Misconfigured text views may ultimately return `nil` here.
    ///
    /// To guarantee that an undo manager is used to track changes to the buffer, use ``init(_:undoManager:)`` and supply an `UndoManager` instance (or use the default instance).
    @inlinable @inline(__always)
    public var undoManager: UndoManager? { getUndoManager() }

    @usableFromInline
    required init(
        _ base: Base,
        getUndoManager: @escaping () -> UndoManager?
    ) {
        self.base = base
        self.getUndoManager = getUndoManager
    }

    /// Wraps `base` to support automatic undo/redo of buffer mutations using `undoManager`.
    ///
    /// > Warning: Nesting `Undoable<Undoable<Undoable<...>>>` is technically possible, but undefined.
    ///
    /// - Parameters:
    ///   - base: Buffer to add undo support for.
    ///   - undoManager: Undo manager to use for undo grouping. By default uses a new `UndoManager` instance per buffer that disables `groupsByEvent` to manually control event grouping instead of automatically grouping operations per `RunLoop` iteration.
    @inlinable
    public convenience init(
        _ base: Base,
        undoManager: UndoManager = {
            let undoManager = UndoManager()
            undoManager.groupsByEvent = false
            return undoManager
        }()
    ) {
        self.init(base) {
            return undoManager
        }
    }

    deinit {
        undoManager?.removeAllActions(withTarget: self)
    }

    public func lineRange(for searchRange: Base.Range) throws -> Base.Range {
        return try base.lineRange(for: searchRange)
    }

    public func content(in range: UTF16Range) throws -> Base.Content {
        return try base.content(in: range)
    }

    public func unsafeCharacter(at location: Location) -> Base.Content {
        return base.unsafeCharacter(at: location)
    }

    public func delete(in deletedRange: Base.Range) throws {
        guard let undoManager
        else { preconditionFailure("Undoable buffer used without UndoManager") }

        let oldContent = try base.content(in: deletedRange)
        let oldSelection = self.isRestoringSelection ? base.selectedRange : nil

        try base.delete(in: deletedRange)

        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.insert(oldContent, at: deletedRange.location)
            if let oldSelection {
                undoableBuffer.withSelectionRestoration(true) {
                    undoableBuffer.select(oldSelection)
                }
            }
        }
        undoManager.endUndoGrouping()
    }

    public func replace(range replacementRange: Base.Range, with content: Base.Content) throws {
        guard let undoManager
        else { preconditionFailure("Undoable buffer used without UndoManager") }

        let oldContent = try base.content(in: replacementRange)
        let oldSelection = self.isRestoringSelection ? base.selectedRange : nil

        try base.replace(range: replacementRange, with: content)

        let newRange = Buffer.Range(location: replacementRange.location, length: length(of: content))
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.replace(range: newRange, with: oldContent)
            if let oldSelection {
                undoableBuffer.withSelectionRestoration(true) {
                    undoableBuffer.select(oldSelection)
                }
            }
        }
        undoManager.endUndoGrouping()
    }

    public func insert(_ content: Base.Content, at location: Base.Location) throws {
        guard let undoManager
        else { preconditionFailure("Undoable buffer used without UndoManager") }

        let oldSelection = self.isRestoringSelection ? base.selectedRange : nil

        try base.insert(content, at: location)

        let newRange = Buffer.Range(location: location, length: length(of: content))
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { undoableBuffer in
            try? undoableBuffer.delete(in: newRange)
            if let oldSelection {
                undoableBuffer.withSelectionRestoration(true) {
                    undoableBuffer.select(oldSelection)
                }
            }
        }
        undoManager.endUndoGrouping()
    }

    /// Wrapping changes inside `block` in a modification request to bundle updates.
    ///
    /// Treats `block` as a single undoable action group. See ``undoGrouping(actionName:undoingSelectionChanges:_:)``
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
    ///   - undoingSelectionChanges: Whether inverse of `select(_:)` commands should also be added to the undo stack during execution of `block`. By default, that's not what users expect on the undo stack as they move the insertion point around. For complex buffer modifications, restoring the original context including the selection is desirable, though.
    ///   - actionName: User-facing action name to set. Can be shown in the Undo/Redo main menu items. `nil` doesn't set any and preserves action names set elsewhere (default).
    ///   - block: Actions to run inside an undo group.
    @inlinable
    public func undoGrouping<T>(
        actionName: String? = nil,
        undoingSelectionChanges: Bool = false,
        _ block: () throws -> T
    ) rethrows -> T {
        guard let undoManager else {
            assertionFailure("Undoable buffer used without UndoManager")
            return try block()
        }

        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        if let actionName {
            undoManager.setActionName(actionName)
        }

        return try withSelectionRestoration(undoingSelectionChanges) {
            return try block()
        }
    }

    /// Run` block` with `isRestoringSelection` enabled or disabled, depending on `isEnabled`.
    public func withSelectionRestoration<T>(
        _ isEnabled: Bool,
        _ block: () throws -> T
    ) rethrows -> T {
        let oldSelectionRestoration = self.isRestoringSelection
        self.isRestoringSelection = isEnabled
        defer { self.isRestoringSelection = oldSelectionRestoration }
        return try block()
    }

    public func undo() {
        assert(undoManager != nil,
               "Undoable buffer used without UndoManager")
        undoManager?.undoNestedGroup()
    }

    public func redo() {
        assert(undoManager != nil,
               "Undoable buffer used without UndoManager")
        undoManager?.redo()
    }
}
