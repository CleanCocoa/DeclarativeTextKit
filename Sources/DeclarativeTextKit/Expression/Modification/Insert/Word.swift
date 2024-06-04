//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Word: Insertable {
    public static let space: Buffer.Content = " "

    public let content: Buffer.Content

    public init(_ content: Buffer.Content) {
        self.content = content
    }

    public func insert(
        in buffer: any Buffer,
        at location: UTF16Offset
    ) throws -> ChangeInLength {
        return try content.insert(in: buffer, at: location)
    }
}
