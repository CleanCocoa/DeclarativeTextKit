//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Swift.String: Insertable {
    @inlinable
    public var content: String { self }

    public func insert(
        in buffer: Buffer,
        at location: UTF16Offset
    ) -> ChangeInLength {
        buffer.insert(self, at: location)
        return ChangeInLength(self)
    }
}
