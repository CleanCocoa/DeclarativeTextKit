//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Ensures its ``content`` is enclosed by space characters left and right upon insertion.
public struct Word: Insertable {
    /// Space character inserted around ``content`` as needed.
    public static let space: Buffer.Content = " "

    public let content: Buffer.Content

    public init(_ content: Buffer.Content) {
        self.content = content
    }

    public func insert(
        in buffer: any Buffer,
        at location: UTF16Offset
    ) throws -> ChangeInLength {
        let whitespaceBefore = location > buffer.range.lowerBound
            ? buffer.containsWhitespaceOrNewline(at: location - 1)
            : true  // Favor not adding a space at the start of a file
        let whitespaceAfter = location < buffer.range.upperBound
            ? buffer.containsWhitespaceOrNewline(at: location)
            : true // Favor not adding a space at the EOF location (we'd want a newline maybe)

        var changeInLength = ChangeInLength()

        if !whitespaceAfter {
            try buffer.insert(Word.space, at: location)
            changeInLength += ChangeInLength(Word.space)
        }

        changeInLength += try content.insert(in: buffer, at: location)

        if !whitespaceBefore {
            try buffer.insert(Word.space, at: location)
            changeInLength += ChangeInLength(Word.space)
        }

        return changeInLength
    }
}

import Foundation

extension Buffer {
    @usableFromInline
    func containsWhitespaceOrNewline(at location: UTF16Offset) -> Bool {
        let character = unsafeCharacter(at: location) as NSString
        return character.rangeOfCharacter(from: .whitespacesAndNewlines) == NSRange(location: 0, length: character.length)
    }
}
