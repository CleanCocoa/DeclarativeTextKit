import Foundation
import TextBuffer

extension ModifiableBuffer {
    @inlinable @inline(__always)
    @discardableResult
    public func evaluate(
        @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try expression().evaluate(in: self)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func evaluate(
        in range: NSRange,
        @ModificationBuilder _ expression: (_ selectedRange: AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try ScopedBufferSlice(
            base: self,
            scopedRange: range
        ).evaluate(in: range, expression)
    }

    @inlinable @inline(__always)
    @discardableResult
    @_disfavoredOverload
    public func evaluate(
        @ModificationBuilder _ expression: (_ fullRange: AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try self.evaluate(in: self.range, expression)
    }
}
