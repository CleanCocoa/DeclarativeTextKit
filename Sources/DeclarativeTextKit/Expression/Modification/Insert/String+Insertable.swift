//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

extension Swift.String: Insertable {
    @inlinable
    public var content: String { self }

    public func insert(
        in buffer: Buffer,
        at location: UTF16Offset
    ) throws -> ChangeInLength {
        try buffer.insert(self, at: location)
        return ChangeInLength(self)
    }
}
