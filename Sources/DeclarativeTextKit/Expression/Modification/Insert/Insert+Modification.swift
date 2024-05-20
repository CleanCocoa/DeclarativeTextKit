//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Insert: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, ModificationFailure> {
        let changeInLength = self.insertions
            .reversed()
            .reduce(into: ChangeInLength()) { changeInLength, insertion in
                changeInLength += insertion.insert(in: buffer)
            }
        return .success(changeInLength)
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) -> ChangeInLength {
        return insertable.insert(in: buffer, at: location)
    }
}
