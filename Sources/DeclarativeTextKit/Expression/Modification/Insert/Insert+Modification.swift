//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Insert: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, ModificationFailure> {
        return Result {
            try self.insertions
                .reversed()
                .reduce(into: ChangeInLength()) { changeInLength, insertion in
                    changeInLength += try insertion.insert(in: buffer)
                }
        }.mapError { error in
            switch error {
            case let error as LocationOutOfBounds:
                return ModificationFailure.outOfRange(
                    requested: .init(location: error.location, length: 0),
                    selected: error.bounds
                )
            default:
                return ModificationFailure.wrapped(error)
            }
        }
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) throws -> ChangeInLength {
        return try insertable.insert(in: buffer, at: location)
    }
}
