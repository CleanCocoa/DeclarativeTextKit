//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert: Modification {
    public func evaluate(in buffer: Buffer) -> ChangeInLength {
        return self.insertions
            .reversed()
            .reduce(into: ChangeInLength()) { changeInLength, insertion in
            changeInLength += insertion.insert(in: buffer)
        }
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: Buffer) -> ChangeInLength {
        return insertable.insert(in: buffer, at: location)
    }
}
