//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Delete: Modification {
    public func evaluate(in buffer: Buffer) -> ChangeInLength {
        return self.deletions
            .reversed()
            .reduce(into: ChangeInLength()) { changeInLength, deletion in
                changeInLength += deletion.delete(from: buffer)
        }
    }
}

extension TextDeletion {
    fileprivate func delete(from buffer: Buffer) -> ChangeInLength {
        buffer.delete(in: self.range)
        return ChangeInLength(-range.length)
    }
}
