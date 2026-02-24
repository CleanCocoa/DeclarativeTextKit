import Foundation
import TextBuffer

public protocol ModifiableBuffer: NSStringBuffer {
    @discardableResult
    func evaluate(
        @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength

    @discardableResult
    @_disfavoredOverload
    func evaluate(
        @ModificationBuilder _ expression: (_ fullRange: AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength

    @inlinable @inline(__always)
    @discardableResult
    func evaluate(
        in range: NSRange,
        @ModificationBuilder _ expression: (_ selectedRange: AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength
}
