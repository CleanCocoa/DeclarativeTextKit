//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

extension Undoable: ModifiableBuffer where Base: ModifiableBuffer {
    /// Wrapping evaluation of `expression` in an undo group to make its evaluation undoable.
    ///
    /// Treats `expression` as a single undoable action group. See ``undoGrouping(actionName:undoingSelectionChanges:_:)``
    ///
    /// - Throws: ``/TextBuffer/BufferAccessFailure`` emitted during evaluation of `expression`.
    @inlinable @discardableResult
    public func evaluate(
      @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try undoGrouping(undoingSelectionChanges: true) {
            return try expression().evaluate(in: self)
        }
    }

    /// Wrapping evaluation of `expression` in an undo group to make its evaluation undoable.
    ///
    /// Treats `expression` as a single undoable action group. See ``undoGrouping(actionName:undoingSelectionChanges:_:)``
    ///
    /// - Throws: ``/TextBuffer/BufferAccessFailure`` emitted during evaluation of `expression`.
    @inlinable @discardableResult
    public func evaluate(
      in range: UTF16Range,
      @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try undoGrouping(undoingSelectionChanges: true) {
            return try expression(AffectedRange(range)).evaluate(in: self)
        }
    }

    /// Wrapping evaluation of `expression` in an undo group to make its evaluation undoable.
    ///
    /// Treats `expression` as a single undoable action group. See ``undoGrouping(actionName:undoingSelectionChanges:_:)``
    ///
    /// - Throws: ``/TextBuffer/BufferAccessFailure`` emitted during evaluation of `expression`.
    @inlinable @discardableResult
    @_disfavoredOverload
    public func evaluate(
      @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try undoGrouping(undoingSelectionChanges: true) {
            return try expression(AffectedRange(self.range)).evaluate(in: self)
        }
    }
}
