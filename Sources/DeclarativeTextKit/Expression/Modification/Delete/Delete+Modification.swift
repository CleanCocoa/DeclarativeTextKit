//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Delete: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return Result {
            try self.deletions
                .reversed()
                .reduce(into: ChangeInLength.empty) { changeInLength, deletion in
                    changeInLength += try deletion.delete(from: buffer)
                }
        }.mapError(BufferAccessFailure.wrap(_:))
    }
}

extension TextDeletion {
    fileprivate func delete(from buffer: Buffer) throws -> ChangeInLength {
        try buffer.delete(in: self.range)
        return ChangeInLength(-range.length)
    }
}
