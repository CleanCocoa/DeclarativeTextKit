//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert: Modification {
    public func apply(to buffer: Buffer) -> ChangeInLength {
        return self.insertions
            .reversed()
            .reduce(into: ChangeInLength()) { changeInLength, insertion in
            changeInLength += insertion.insert(in: buffer)
        }
    }

    @inlinable
    public func callAsFunction(intoBuffer buffer: Buffer) -> ChangeInLength {
        return apply(to: buffer)
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) -> ChangeInLength {
        return insertable.insert(in: buffer, at: location)
    }
}
