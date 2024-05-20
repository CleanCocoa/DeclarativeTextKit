//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Delete: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, ModificationFailure> {
        let changeInLength = self.deletions
            .reversed()
            .reduce(into: ChangeInLength()) { changeInLength, deletion in
                changeInLength += deletion.delete(from: buffer)
            }
        return .success(changeInLength)
    }
}

extension TextDeletion {
    fileprivate func delete(from buffer: Buffer) -> ChangeInLength {
        buffer.delete(in: self.range)
        return ChangeInLength(-range.length)
    }
}
