//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert {
    public func apply(to buffer: Buffer) {
        self.insertions.reversed()
            .forEach { $0.insert(in: buffer) }
    }

    @inlinable
    public func callAsFunction(intoBuffer buffer: Buffer) {
        apply(to: buffer)
    }
}

extension TextInsertion {
    func insert(in buffer: Buffer) {
        insertable.insert(in: buffer, at: location)
    }
}
