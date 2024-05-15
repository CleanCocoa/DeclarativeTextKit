//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert: Modification {
    public func apply(to buffer: Buffer) -> ChangeInLength {
        var changeInLength = ChangeInLength()

        for insertion in self.insertions.reversed() {
            changeInLength += insertion.insert(in: buffer)
        }

        return changeInLength
    }

    @inlinable
    @discardableResult
    public func callAsFunction(intoBuffer buffer: Buffer) -> ChangeInLength {
        return apply(to: buffer)
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) -> ChangeInLength {
        insertable.insert(in: buffer, at: location)
    }
}
