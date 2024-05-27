//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Insert: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return Result {
            try self.insertions
                .reversed()
                .reduce(into: ChangeInLength.empty) { changeInLength, insertion in
                    changeInLength += try insertion.insert(in: buffer)
                }
        }.mapError(BufferAccessFailure.wrap(_:))
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) throws -> ChangeInLength {
        return try insertable.insert(in: buffer, at: location)
    }
}
