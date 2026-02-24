import TextBuffer

public struct Word: Insertable {
    public static let space: String = " "

    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func insert(
        in buffer: any NSStringBuffer,
        at location: Int
    ) throws -> ChangeInLength {
        let whitespaceBefore = location > buffer.range.lowerBound
            ? buffer.containsWhitespaceOrNewline(at: location - 1)
            : true
        let whitespaceAfter = location < buffer.range.upperBound
            ? buffer.containsWhitespaceOrNewline(at: location)
            : true

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
    public typealias Prepending = StartsWithSpaceIfNeeded
    public typealias Appending = EndsWithSpaceIfNeeded

    public struct StartsWithSpaceIfNeeded: Insertable {
        public let content: String

        @inlinable
        public init(_ content: String) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: any NSStringBuffer,
            at location: Int
        ) throws -> ChangeInLength {
            let whitespaceBefore = location > buffer.range.lowerBound
                ? buffer.containsWhitespaceOrNewline(at: location - 1)
                : true

            var changeInLength = ChangeInLength()

            changeInLength += try content.insert(in: buffer, at: location)

            if !whitespaceBefore {
                try buffer.insert(Word.space, at: location)
                changeInLength += ChangeInLength(Word.space)
            }

            return changeInLength
        }
    }

    public struct EndsWithSpaceIfNeeded: Insertable {
        public let content: String

        @inlinable
        public init(_ content: String) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: any NSStringBuffer,
            at location: Int
        ) throws -> ChangeInLength {
            let whitespaceAfter = location < buffer.range.upperBound
                ? buffer.containsWhitespaceOrNewline(at: location)
                : true

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

extension NSStringBuffer {
    @usableFromInline
    func containsWhitespaceOrNewline(at location: Int) -> Bool {
        let character = unsafeCharacter(at: location) as NSString
        return character.rangeOfCharacter(from: .whitespacesAndNewlines) == NSRange(location: 0, length: character.length)
    }
}
