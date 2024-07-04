//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Buffer {
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
        in range: Buffer.Range,
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
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
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try self.evaluate(in: self.range, expression)
    }
}
