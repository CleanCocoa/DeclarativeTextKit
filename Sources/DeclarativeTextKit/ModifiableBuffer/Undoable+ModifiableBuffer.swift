import Foundation
import TextBuffer

extension Undoable: @MainActor ModifiableBuffer where Base: ModifiableBuffer {
    @inlinable @discardableResult
    public func evaluate(
      @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try undoGrouping(undoingSelectionChanges: true) {
            return try expression().evaluate(in: self)
        }
    }

    @inlinable @discardableResult
    public func evaluate(
      in range: NSRange,
      @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try undoGrouping(undoingSelectionChanges: true) {
            return try expression(AffectedRange(range)).evaluate(in: self)
        }
    }

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
