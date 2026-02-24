import Foundation
import TextBuffer

extension Delete: Modification {
    @_disfavoredOverload
    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return Result {
            try self.deletions()
                .reversed()
                .reduce(into: ChangeInLength.empty) { changeInLength, deletion in
                    changeInLength += try deletion.delete(from: buffer)
                }
        }.mapError(BufferAccessFailure.wrap(_:))
    }
}

extension TextDeletion {
    fileprivate func delete(from buffer: any NSStringBuffer) throws -> ChangeInLength {
        try buffer.delete(in: self.range)
        return ChangeInLength(-range.length)
    }
}
