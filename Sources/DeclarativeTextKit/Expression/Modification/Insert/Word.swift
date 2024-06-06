//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Ensures its ``content`` is enclosed by space characters left and right upon insertion, otherwise inserting a ``Word/space`` character as separator where needed.
///
/// Does not insert a space at the ``Buffer``'s zero location (or start position), nor at its end.
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

// MARK: Half-Padded Word

extension Word {
    /// Makes sure to pad the left-hand side with a space (if needed) as word separator.
    public typealias Prepending = StartsWithSpaceIfNeeded
    /// Makes sure to pad the right-hand side with a space (if needed) as word separator.
    public typealias Appending = EndsWithSpaceIfNeeded

    /// Ensures its ``content`` is preceded by any whitespace characters (to the left), otherwise inserting a ``Word/space`` character.
    ///
    /// At the ``Buffer``'s zero location or start position, does not prepend a space.
    public struct StartsWithSpaceIfNeeded: Insertable {
        public let content: Buffer.Content

        @inlinable
        public init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: Buffer,
            at location: UTF16Offset
        ) throws -> ChangeInLength {
            let whitespaceBefore = location > buffer.range.lowerBound
                ? buffer.containsWhitespaceOrNewline(at: location - 1)
                : true  // Favor not adding a space at the start of a file

            var changeInLength = ChangeInLength()

            changeInLength += try content.insert(in: buffer, at: location)

            if !whitespaceBefore {
                try buffer.insert(Word.space, at: location)
                changeInLength += ChangeInLength(Word.space)
            }

            return changeInLength
        }
    }

    /// Ensures its ``content`` is followed by any whitespace characters (to the right), otherwise inserting a ``Word/space`` character.    ///
    ///
    /// At the ``Buffer``'s end position, does not append a space.
    public struct EndsWithSpaceIfNeeded: Insertable {
        public let content: Buffer.Content

        @inlinable
        public init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: Buffer,
            at location: UTF16Offset
        ) throws -> ChangeInLength {
            let whitespaceAfter = location < buffer.range.upperBound
                ? buffer.containsWhitespaceOrNewline(at: location)
                : true // Favor not adding a space at the EOF location (we'd want a newline maybe)

            var changeInLength = ChangeInLength()

            if !whitespaceAfter {
                try buffer.insert(Word.space, at: location)
                changeInLength += ChangeInLength(Word.space)
            }

            changeInLength += try content.insert(in: buffer, at: location)

            return changeInLength
        }
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
